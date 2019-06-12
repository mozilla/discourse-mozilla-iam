module MozillaIAM
  module API
    class PersonV2 < OAuth

      def initialize(config={})
        config = {
          url: SiteSetting.mozilla_iam_person_v2_api_url + "/v2",
          aud: SiteSetting.mozilla_iam_person_v2_api_aud
        }.merge(config)
        super(config)
      end

      def profile(uid)
        res = get("user/user_id/#{uid}")
        Profile.new(res)
      end

      class Profile
        attr_reader :username
        attr_reader :pronouns
        attr_reader :full_name
        attr_reader :fun_title
        attr_reader :description
        attr_reader :location
        attr_reader :picture
        attr_reader :profile_url

        def initialize(raw)
          @raw = raw
          @username = process :primary_username
          @pronouns = process :pronouns
          @full_name = process_full_name
          @fun_title = process :fun_title
          @description = process :description
          @location = process :location
          @picture = process_picture
          @profile_url = process_profile_url
        end

        def blank?
          @raw.blank?
        end

        def to_hash
          hash = {}
          (instance_variables - [:@raw]).each do |var|
            hash[var.to_s.delete_prefix("@")] = instance_variable_get(var)
          end
          hash
        end

        private

        def process(name)
          if field = @raw[name]
            metadata = field[:metadata]
            if metadata[:display] == "public" && metadata[:verified] == true
              return field[:value]
            end
          end
          nil
        end

        def process_full_name
          first = process :first_name
          last = process :last_name
          return "#{first} #{last}" unless first.blank? || last.blank?

          alternative = process :alternative_name
          return "#{alternative}" unless alternative.blank?

          return "#{first}" unless first.blank?
          return "#{last}" unless last.blank?
        end

        def process_picture
          url = process :picture
          if !url.blank? && url.starts_with?("/")
            SiteSetting.dinopark_url.chomp("/") + url
          else
            url
          end
        end

        def process_profile_url
          name = process :primary_username
          SiteSetting.dinopark_url.chomp("/") + "/p/" + name unless name.nil?
        end
      end
    end
  end
end
