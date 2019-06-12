require_relative '../../../iam_helper'

describe MozillaIAM::Profile do
  describe "#dinopark_enabled" do
    let(:user) { Fabricate(:user) }
    let(:profile) { MozillaIAM::Profile.new(user, "uid") }

    it "defaults to false" do
      expect(profile.dinopark_enabled?).to eq false
    end

    it "can be set to true" do
      profile.dinopark_enabled = true
      expect(profile.dinopark_enabled?).to eq true
    end

    it "returns false if set to anything but true" do
      profile.dinopark_enabled = "blah"
      expect(profile.dinopark_enabled?).to eq false
    end

  end
end
