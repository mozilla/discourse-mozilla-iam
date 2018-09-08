module MozillaIAM
  class Profile
    @refresh_methods = []
    @array_keys = []

    class << self
      attr_accessor :refresh_methods
      attr_accessor :array_keys

      def during_refresh(method_name)
        refresh_methods << method_name
      end

      def register_as_array(key)
        array_keys << key
      end

      def for(user)
        uid = get(user, :uid)
        return if uid.blank?
        Profile.new(user, uid)
      end

      def refresh(user)
        profile = self.for(user)
        profile.refresh unless profile.nil?
      end
    end

    def initialize(user, uid)
      @user = user
      @uid = set(:uid, uid)
      @api_profiles = {}
    end

    def refresh
      return last_refresh unless should_refresh?
      force_refresh
    end

    def force_refresh
      DistributedMutex.synchronize("mozilla_iam_refresh_#{@user.id}") do
        @api_profiles = {}
        self.class.refresh_methods.each { |name| self.send(name) }
        set_last_refresh(Time.now)
      end
    end

    def attr(attr)
      apis = API.profile_apis.select { |api| api::Profile.method_defined? attr }
      response = nil
      apis.each do |api|
        @api_profiles[api.name] ||= api.profile(@uid)
        value = @api_profiles[api.name].send(attr)
        if response.nil?
          response = value
        elsif [response, value].map { |x| x.kind_of? Array }.all?
          response = response | value
        end
      end
      return response
    end

    def last_refresh
      @last_refresh ||=
        if time = get(:last_refresh)
          Time.parse(time)
        end
    end

    private

    def set_last_refresh(time)
      @last_refresh = set(:last_refresh, time)
    end

    def should_refresh?
      return true unless last_refresh
      Time.now > last_refresh + 900
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
end

require_relative "profile/update_groups"
require_relative "profile/update_emails"
require_relative "profile/duplicate_accounts"
