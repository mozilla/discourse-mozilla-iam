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
        attr_reader :secondary_emails
        attr_reader :email

        def initialize(raw)
          @raw = raw
          @groups = Array(raw[:groups]) | Array(raw.dig(:app_metadata, :groups))
          @secondary_emails = Array(raw[:email_aliases])
          @email = raw[:email]
        end
      end
    end
  end
end
