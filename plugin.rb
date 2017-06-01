# name: mozilla-iam
# about: A plugin to integrate Discourse with Mozilla's Identity and Access Management (IAM) system
# version: 0.0.1
# authors: Leo McArdle
# url: https://github.com/mozilla/discourse-mozilla-iam

gem 'omniauth-auth0', '2.0.0'
gem 'jwt', '1.5.6'
gem 'auth0', '4.1.0'

require 'faraday'
require 'multi_json'
require 'base64'
require 'openssl'
require 'auth/oauth2_authenticator'

class MozillaIAM
  class Authenticator < Auth::OAuth2Authenticator
    def after_authenticate(auth_token)
      begin
        id_token = auth_token[:credentials][:id_token]
        public_key = JWKS.public_key(id_token)

        payload, header =
          JWT.decode(
            id_token,
            public_key,
            true,
            {
              algorithm: 'RS256',
              iss: 'https://' + SiteSetting.auth0_domain + '/',
              verify_iss: true,
              aud: SiteSetting.auth0_client_id,
              verify_aud: true,
              verify_iat: true
            }
          )

        logout_delay = payload['exp'] - payload['iat']
        ::PluginStore.set('mozilla-iam', 'logout_delay', logout_delay)

        auth_token[:session][:last_refreshed] = Time.now
      rescue => e
        result = Auth::Result.new
        result.failed = true
        result.failed_reason = 'Authentication failed'
        result.failed_reason += ': ' + e.message unless e.message.blank?
        Rails.logger.error("#{e.class} (#{e.message})\n#{e.backtrace.join("\n")}")
        return result
      end

      super
    end

    def register_middleware(omniauth)
      omniauth.provider(
        :auth0,
        SiteSetting.auth0_client_id,
        SiteSetting.auth0_client_secret,
        SiteSetting.auth0_domain,
        {
          authorize_params: {
            scope: 'openid'
          }
        }
      )
    end
  end

  class JWKS
    def self.public_key(jwt)
      header, payload = JWT.decoded_segments(jwt)
      key = jwks['keys'].find { |key| key['kid'] == header['kid'] }
      cert = OpenSSL::X509::Certificate.new(Base64.decode64(key['x5c'][0]))
      cert.public_key
    end

    def self.jwks
      response = Faraday.get('https://' + SiteSetting.auth0_domain + '/.well-known/jwks.json')
      MultiJson.load(response.body)
    end
  end

  module ApplicationExtensions
    def check_iam_session
      begin
        last_refresh = session[:last_refreshed]
        if !last_refresh.nil? && current_user
          refresh_delay = 900 # == 60 * 15
          now = Time.now
          if last_refresh + refresh_delay < now
            logout_delay = ::PluginStore.get('mozilla-iam', 'logout_delay')
            if last_refresh + logout_delay < now
              reset_session
              log_off_user
            else
              refresh_iam_session
            end
          end
        end
      rescue => e
        reset_session
        log_off_user
        raise e
      end
    end

    def refresh_iam_session
      oauth2_user_info = current_user.oauth2_user_info

      if oauth2_user_info
        auth0 = Auth0Client.new(
          client_id: SiteSetting.auth0_client_id,
          token: iam_token,
          domain: SiteSetting.auth0_domain
        )

        user_id = oauth2_user_info.uid
        auth0.user(user_id)
        session[:last_refreshed] = Time.now
      else
        session[:last_refreshed] = nil
      end
    end

    def iam_token
      api_token = ::PluginStore.get('mozilla-iam', 'api_token')
      if api_token.nil? || api_token[:exp] < Time.now.to_i + 60
        refresh_iam_token
      else
        api_token[:jwt]
      end
    end

    def refresh_iam_token
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
      token = MultiJson.load(response.body)['access_token']

      public_key = JWKS.public_key(token)

      payload, header =
        JWT.decode(
          token,
          public_key,
          true,
          {
            algorithm: 'RS256',
            iss: 'https://' + SiteSetting.auth0_domain + '/',
            verify_iss: true,
            aud: 'https://' + SiteSetting.auth0_domain + '/api/v2/',
            verify_aud: true,
            verify_iat: true,
            sub: SiteSetting.auth0_client_id + '@clients',
            verify_sub: true
          }
        )

      ::PluginStore.set('mozilla-iam', 'api_token', { jwt: token, exp: payload['exp'] })

      token
    end
  end
end

after_initialize do
  ApplicationController.include MozillaIAM::ApplicationExtensions
  ApplicationController.class_eval do
    before_filter :check_iam_session
  end
end

register_asset 'stylesheets/hide-sign-up.scss'

auth_provider(title: 'Mozilla',
              message: 'Log In / Sign Up',
              authenticator: MozillaIAM::Authenticator.new('auth0', trusted: true),
              full_screen_login: true)
