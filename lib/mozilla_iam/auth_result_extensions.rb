module MozillaIAM
  module AuthResultExtensions

    def to_client_hash
      result = super
      return result unless extra_data[:show_dinopark_prompt]
      profile = MozillaIAM::API::PersonV2.new.profile(extra_data[:uid])
      unless profile.blank?
        result.merge!({
          dinopark_profile: profile.to_hash
        })
      end
      result
    end

  end
end
