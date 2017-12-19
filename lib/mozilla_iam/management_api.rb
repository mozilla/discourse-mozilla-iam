module MozillaIAM
  class ManagementAPI < API

    def initialize(config={})
      config = {
        url: "https://#{SiteSetting.auth0_domain}/api/v2",
        aud: "https://#{SiteSetting.auth0_domain}/api/v2/"
      }.merge(config)
      super(config)
    end

    def profile(uid)
      profile = get("users/#{uid}", fields: "app_metadata")
      { app_metadata: {} }.merge(profile)[:app_metadata]
    end

  end
end
