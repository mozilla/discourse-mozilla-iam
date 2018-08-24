module MozillaIAM
  module API
    class Person < OAuth

      def initialize(config={})
        config = {
          url: SiteSetting.mozilla_iam_person_api_url + "/v1",
          aud: SiteSetting.mozilla_iam_person_api_aud
        }.merge(config)
        super(config)
      end

      def profile(uid)
        res = get("profile/#{uid}")
        Profile.new(MultiJson.load(res[:body], symbolize_keys: true))
      end

      class Profile
        attr_reader :secondary_emails

        def initialize(raw)
          @raw = raw
          @secondary_emails = process_emails
        end

        private

        def process_emails
          emails = @raw[:emails]
          if emails
            emails.select { |x| x[:verified] && !x[:primary] }.map { |x| x[:value] }.uniq
          else
            []
          end
        end
      end
    end
  end
end
