module MozillaIAM
  module API
    class Management < OAuth

      def initialize(config={})
        config = {
          url: "https://#{SiteSetting.auth0_domain}/api/v2",
          aud: "https://#{SiteSetting.auth0_domain}/api/v2/"
        }.merge(config)
        super(config)
      end

      def profile(uid)
        Profile.new(get("users/#{uid}"))
      end

      class Profile
        attr_reader :groups

        def initialize(raw)
          @raw = raw
          @groups = Array(raw[:groups]) | Array(raw.dig(:app_metadata, :groups))
        end
      end
    end
  end
end
