require_relative "../../iam_helper"

describe MozillaIAM::PersonAPI do
  let(:api) { MozillaIAM::PersonAPI.new }
  before do
    SiteSetting.mozilla_iam_person_api_url = "https://person.com"
    SiteSetting.mozilla_iam_person_api_aud = "person.com"
  end

  context "#initialize" do
    it "sets url and aud based on SiteSetting" do
      expect(api.instance_variable_get(:@url)).to eq "https://person.com"
      expect(api.instance_variable_get(:@aud)).to eq "person.com"
    end
  end

  context "#profile" do
    it "returns the profile for a specific user" do
      api.expects(:get).with("profile/uid").returns(body: '{"profile":"profile"}')
      expect(api.profile("uid")[:profile]).to eq "profile"
    end

    it "returns an empty hash if a profile doesn't exist" do
      api.expects(:get).with("profile/uid").returns(body: '{}')
      expect(api.profile("uid")).to eq({})
    end
  end
end
