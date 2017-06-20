# name: mozilla-iam
# about: A plugin to integrate Discourse with Mozilla's Identity and Access Management (IAM) system
# version: 0.0.1
# authors: Leo McArdle
# url: https://github.com/mozilla/discourse-mozilla-iam

gem 'omniauth-auth0', '2.0.0'

gem 'netrc', '0.11.0', require: false
gem 'domain_name', '0.5.20170404', require: false
gem 'http-cookie', '1.0.3', require: false
gem 'rest-client', '1.8.0', require: false
gem 'auth0', '4.1.0'

require 'jwt'
require 'faraday'
require 'multi_json'
require 'base64'
require 'openssl'

require 'auth/oauth2_authenticator'
require 'admin_constraint'

module ::MozillaIAM
  class Authenticator < Auth::OAuth2Authenticator
    def after_authenticate(auth_token)
      begin
        id_token = auth_token[:credentials][:id_token]
        payload, header =
          JWT.decode(
            id_token,
            aud: SiteSetting.auth0_client_id
          )

        logout_delay = payload['exp'] - payload['iat']
        ::PluginStore.set('mozilla-iam', 'logout_delay', logout_delay)
        Rails.cache.write('mozilla-iam/logout_delay', logout_delay)

        auth_token[:session][:mozilla_iam] = {
          last_refresh: Time.now
        }

        result = Auth::Result.new

        result.email = email = payload['email']
        result.user = user = User.find_by_email(email)
        result.email_valid = payload['email_verified']
        result.name = payload['name']
        uid = payload['sub']
        result.extra_data = { uid: uid }

        if user
          Profile.new(user, uid).refresh
        end

        result
      rescue => e
        result = Auth::Result.new
        result.failed = true
        result.failed_reason = I18n.t("login.omniauth_error")
        Rails.logger.error("#{e.class} (#{e.message})\n#{e.backtrace.join("\n")}")
        return result
      end
    end

    def after_create_account(user, auth)
      uid = auth[:extra_data][:uid]
      Profile.new(user, uid).refresh
    end

    def register_middleware(omniauth)
      omniauth.provider(
        :auth0,
        SiteSetting.auth0_client_id,
        SiteSetting.auth0_client_secret,
        SiteSetting.auth0_domain,
        {
          authorize_params: {
            scope: 'openid name email'
          }
        }
      )
    end
  end

  class JWKS
    def self.public_key(jwt)
      header, payload = ::JWT.decoded_segments(jwt)
      key = jwks['keys'].find { |key| key['kid'] == header['kid'] }
      cert = OpenSSL::X509::Certificate.new(Base64.decode64(key['x5c'][0]))
      cert.public_key
    end

    def self.jwks
      response = Faraday.get('https://' + SiteSetting.auth0_domain + '/.well-known/jwks.json')
      MultiJson.load(response.body)
    end
  end

  class JWT
    def self.decode(token, opts)
      public_key = JWKS.public_key(token)
      ::JWT.decode(
        token,
        public_key,
        true,
        {
          algorithm: 'RS256',
          iss: 'https://' + SiteSetting.auth0_domain + '/',
          verify_iss: true,
          verify_iat: true,
          verify_aud: true
        }.merge(opts)
      )
    end
  end

  module ApplicationExtensions
    def check_iam_session
      begin
        last_refresh = session[:mozilla_iam].try(:[], :last_refresh)
        logout_delay =
          Rails.cache.fetch('mozilla-iam/logout_delay') do
            ::PluginStore.get('mozilla-iam', 'logout_delay')
          end

        return if last_refresh.nil? || !current_user
        if last_refresh + logout_delay < Time.now
          reset_session
          log_off_user
        else
          refresh_iam_session
        end
      rescue => e
        reset_session
        log_off_user
        raise e
      end
    end

    def refresh_iam_session
      session[:mozilla_iam][:last_refresh] = Profile.refresh(current_user)
    end
  end

  class API
    def self.user_profile(uid)
      auth0 = Auth0Client.new(
        client_id: SiteSetting.auth0_client_id,
        token: access_token,
        domain: SiteSetting.auth0_domain
      )

      Rails.logger.info("Auth0 API query for user_id: #{uid}")

      auth0.user(uid)['app_metadata']
    end

    def self.access_token
      api_creds = ::PluginStore.get('mozilla-iam', 'api_creds')
      if api_creds.nil? || api_creds[:exp] < Time.now.to_i + 60
        refresh_token
      else
        api_creds[:access_token]
      end
    end

    def self.refresh_token
      token = fetch_token
      payload = verify_token(token)
      ::PluginStore.set('mozilla-iam', 'api_creds', { access_token: token, exp: payload['exp'] })
      token
    end

    def self.fetch_token
      response =
        Faraday.post(
          'https://' + SiteSetting.auth0_domain + '/oauth/token',
          {
            grant_type: 'client_credentials',
            client_id: SiteSetting.auth0_client_id,
            client_secret: SiteSetting.auth0_client_secret,
            audience: 'https://' + SiteSetting.auth0_domain + '/api/v2/'
          }
        )
      MultiJson.load(response.body)['access_token']
    end

    def self.verify_token(token)
      payload, header =
        JWT.decode(
          token,
          aud: 'https://' + SiteSetting.auth0_domain + '/api/v2/',
          sub: SiteSetting.auth0_client_id + '@clients',
          verify_sub: true
        )
      payload
    end
  end

  class Profile
    def self.refresh(user)
      uid = get(user, :uid)
      return if uid.blank?
      Profile.new(user, uid).refresh
    end

    def initialize(user, uid)
      @user = user
      @uid = set(:uid, uid)
    end

    def refresh
      DistributedMutex.synchronize("mozilla_iam_refresh_#{@user.id}") do
        return last_refresh unless should_refresh?
        update_groups
        set_last_refresh(Time.now)
      end
    end

    private

    def profile
      @profile ||= API.user_profile(@uid)
    end

    def last_refresh
      @last_refresh ||=
        if time = get(:last_refresh)
          Time.parse(time)
        end
    end

    def set_last_refresh(time)
      @last_refresh = set(:last_refresh, time)
    end

    def should_refresh?
      return true unless last_refresh
      if Rails.env.production?
        Time.now > last_refresh + 900
      else
        Time.now > last_refresh + 15
      end
    end

    def update_groups
      GroupMapping.all.each do |mapping|
        if mapping.authoritative
          in_group =
            profile['authoritativeGroups'].any? do |authoritative_group|
              authoritative_group['name'] == mapping.iam_group_name
            end
        else
          in_group = profile['groups'].include?(mapping.iam_group_name)
        end

        if in_group
          add_to_group(mapping.group)
        else
          remove_from_group(mapping.group)
        end
      end
    end

    def add_to_group(group)
      unless group.users.exists?(@user.id)
        group.users << @user
      end
    end

    def remove_from_group(group)
      group.users.delete(@user)
    end

    def self.get(user, key)
      user.custom_fields["mozilla_iam_#{key}"]
    end

    def get(key)
      self.class.get(@user, key)
    end

    def self.set(user, key, value)
      user.custom_fields["mozilla_iam_#{key}"] = value
      user.save_custom_fields
      value
    end

    def set(key, value)
      self.class.set(@user, key, value)
    end
  end

  module PostAlerterExtensions
    def create_notification(user, type, post, opts = {})
      Profile.refresh(user) if post.topic.category.read_restricted
      super(user, type, post, opts)
    end
  end

  module UserNotificationsExtensions
    def notification_email(user, opts)
      post = opts[:post]
      Profile.refresh(user) if post.topic.category.read_restricted
      super(user, opts)
    end
  end
end

after_initialize do
  require_dependency 'admin/admin_controller'

  ApplicationController.include MozillaIAM::ApplicationExtensions
  ApplicationController.class_eval do
    before_filter :check_iam_session
  end

  PostAlerter.prepend MozillaIAM::PostAlerterExtensions
  UserNotifications.prepend MozillaIAM::UserNotificationsExtensions

  module ::MozillaIAM
    class Engine < ::Rails::Engine
      engine_name 'mozilla_iam'
      isolate_namespace MozillaIAM
    end
  end

  ActiveSupport::Inflector.inflections do |inflect|
    inflect.acronym 'IAM'
  end

  MozillaIAM::Engine.routes.draw do
    namespace :admin, constraints: AdminConstraint.new do
      resources :group_mappings, path: :mappings
    end
  end

  Discourse::Application.routes.append do
    get '/admin/plugins/mozilla-iam' => 'admin/plugins#index'
    get '/admin/plugins/mozilla-iam/*all' => 'admin/plugins#index'
    mount MozillaIAM::Engine => '/mozilla_iam'
  end

  class MozillaIAM::GroupMapping < ActiveRecord::Base
    belongs_to :group
  end

  class MozillaIAM::GroupMappingSerializer < ApplicationSerializer
    attributes :id,
               :group_name,
               :iam_group_name,
               :authoritative

    def group_name
      object.group.name
    end
  end

  class MozillaIAM::Admin
    class GroupMappingsController < ::Admin::AdminController

      def index
        mappings = MozillaIAM::GroupMapping.all
        render_serialized(mappings, MozillaIAM::GroupMappingSerializer)
      end

      def new
      end

      def create
        mapping = MozillaIAM::GroupMapping.new(group_mappings_params)
        mapping.authoritative = false if params[:authoritative].nil?
        mapping.group = Group.find_by(name: params[:group_name])
        mapping.save!
        render json: success_json
      end

      def show
        params.require(:id)
        mapping = MozillaIAM::GroupMapping.find(params[:id])
        render_serialized(mapping, MozillaIAM::GroupMappingSerializer)
      end

      def update
        params.require(:id)
        mapping = MozillaIAM::GroupMapping.find(params[:id])
        mapping.update_attributes!(group_mappings_params)
        render json: success_json
      end

      def destroy
        params.require(:id)
        mapping = MozillaIAM::GroupMapping.find(params[:id])
        mapping.destroy
        render json: success_json
      end

      def group_mappings_params
        params.permit(
          :id,
          :iam_group_name,
          :authoritative
        )
      end

    end
  end
end

add_admin_route 'mozilla_iam.mappings.title', 'mozilla-iam.mappings'

register_asset 'stylesheets/hide-sign-up.scss'

auth_provider(title: 'Mozilla',
              message: 'Log In / Sign Up',
              authenticator: MozillaIAM::Authenticator.new('auth0', trusted: true),
              full_screen_login: true)
