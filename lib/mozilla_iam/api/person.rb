module MozillaIAM
  class PersonAPI < API

    def initialize(config={})
      config = {
        url: SiteSetting.mozilla_iam_person_api_url + "/v1",
        aud: SiteSetting.mozilla_iam_person_api_aud
      }.merge(config)
      super(config)
    end

    def profile(uid)
      profile = get("profile/#{uid}")
      MultiJson.load(profile[:body], symbolize_keys: true)
    end

  end
end
