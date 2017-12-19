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
      get("users/#{uid}")
    end

  end
end
