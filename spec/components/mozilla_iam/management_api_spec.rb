require_relative "../../iam_helper"

describe MozillaIAM::ManagementAPI do
  let(:api) { MozillaIAM::ManagementAPI.new }
  before do
    SiteSetting.auth0_domain = "foobar.com"
  end

  context "#initialize" do
    it "sets url and aud based on auth0_domain" do
      expect(api.instance_variable_get(:@url)).to eq "https://foobar.com/api/v2"
      expect(api.instance_variable_get(:@aud)).to eq "https://foobar.com/api/v2/"
    end
  end

  context "#profile" do
    it "returns the management api profile" do
      api.expects(:get).with("users/uid").returns("profile")
      expect(api.profile("uid")).to eq "profile"
    end

    it "returns an empty hash if a profile doesn't exist" do
      api.expects(:get).with("users/uid").returns({})
      expect(api.profile("uid")).to eq({})
    end
  end
end
