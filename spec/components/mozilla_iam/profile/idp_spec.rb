require_relative '../../../iam_helper'

describe MozillaIAM::Profile do
  describe "#idp" do
    let(:user) { Fabricate(:user) }

    it "interprets ldap uids" do
      profile = described_class.new user, "ad|Mozilla-LDAP|jdoe"
      expect(profile.idp).to eq "LDAP"
    end

    it "interprets firefox uids" do
      profile = described_class.new user, "oauth2|firefoxaccounts|12345"
      expect(profile.idp).to eq "Firefox"
    end

    it "interprets github uids" do
      profile = described_class.new user, "github|12345"
      expect(profile.idp).to eq "GitHub"
    end

    it "interprets google uids" do
      profile = described_class.new user, "google-oauth2|12345"
      expect(profile.idp).to eq "Google"
    end

    it "interprets email uids" do
      profile = described_class.new user, "email|12345"
      expect(profile.idp).to eq "Email"
    end

    it "doesn't fail with unknown uids" do
      profile = described_class.new user, "uid"
      expect(profile.idp).to eq "Unknown"
    end
  end
end
