require_relative "../../../iam_helper"

describe MozillaIAM::API::Person do
  let(:api) { described_class.new }
  before do
    SiteSetting.mozilla_iam_person_api_url = "https://person.com"
    SiteSetting.mozilla_iam_person_api_aud = "person.com"
  end

  context "#initialize" do
    it "sets url and aud based on SiteSetting" do
      expect(api.instance_variable_get(:@url)).to eq "https://person.com/v1"
      expect(api.instance_variable_get(:@aud)).to eq "person.com"
    end
  end

  context "#profile" do
    it "returns the profile for a specific user" do
      api.expects(:get).with("profile/uid").returns(body: '{"profile":"profile"}')
      expect(api.profile("uid").instance_variable_get(:@raw)).to eq({profile: "profile"})
    end

    it "returns an empty hash if a profile doesn't exist" do
      api.expects(:get).with("profile/uid").returns(body: '{}')
      expect(api.profile("uid").instance_variable_get(:@raw)).to eq({})
    end
  end

  describe described_class::Profile do
    describe "#secondary_emails" do
      context "with no emails attribute in profile" do
        let(:profile) { described_class.new({}) }

        it "returns empty array" do
          expect(profile.secondary_emails).to eq []
        end
      end

      context "with empy emails attribute in profile" do
        let(:profile) { described_class.new({ emails: [] }) }

        it "returns empty array" do
          expect(profile.secondary_emails).to eq []
        end
      end

      context "with primary email in profile" do
        let(:profile) { described_class.new({ emails: [
          { verified: true, value: "first@example.com", primary: true }
        ] }) }

        it "returns empty array" do
          expect(profile.secondary_emails).to eq []
        end
      end

      context "with multiple primary emails in profile" do
        let(:profile) { described_class.new({ emails: [
          { verified: true, value: "first@example.com", primary: true },
          { verified: true, value: "second@example.com", primary: true }
        ] }) }

        it "returns empty array" do
          expect(profile.secondary_emails).to eq []
        end
      end

      context "secondary emails in profile" do
        let(:profile) { described_class.new({ emails: [
          { verified: true, value: "first@example.com", primary: true },
          { verified: true, value: "second@example.com", primary: false },
          { verified: true, value: "third@example.com", primary: false },
        ] }) }

        it "returns secondary emails" do
          expect(profile.secondary_emails).to contain_exactly("second@example.com", "third@example.com")
        end
      end

      context "with unverified emails in profile" do
        let(:profile) { described_class.new({ emails: [
          { verified: false, value: "first_unverified@example.com", primary: true },
          { verified: true, value: "first@example.com", primary: true },
          { verified: false, value: "second_unverified@example.com", primary: true },
          { verified: true, value: "second@example.com", primary: false },
          { verified: true, value: "third@example.com", primary: false },
        ] }) }

        it "returns verified secondary emails" do
          expect(profile.secondary_emails).to contain_exactly("second@example.com", "third@example.com")
        end
      end
    end
  end
end
