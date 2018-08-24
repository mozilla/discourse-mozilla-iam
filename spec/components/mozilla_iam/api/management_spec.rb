require_relative "../../../iam_helper"

describe MozillaIAM::API::Management do
  let(:api) { described_class.new }
  before do
    SiteSetting.auth0_domain = "foobar.com"
  end

  describe "#initialize" do
    it "sets url and aud based on auth0_domain" do
      expect(api.instance_variable_get(:@url)).to eq "https://foobar.com/api/v2"
      expect(api.instance_variable_get(:@aud)).to eq "https://foobar.com/api/v2/"
    end
  end

  describe "#profile" do
    it "returns the management api profile" do
      api.expects(:get).with("users/uid").returns({profile: true})
      expect(api.profile("uid").instance_variable_get(:@raw)).to eq({profile: true})
    end

    it "returns an empty hash if a profile doesn't exist" do
      api.expects(:get).with("users/uid").returns({})
      expect(api.profile("uid").instance_variable_get(:@raw)).to eq({})
    end
  end

  describe described_class::Profile do
    describe "#groups" do
      shared_examples "union" do
        it "takes the union of groups and app_metadata.groups" do
          expect(profile.groups).to match_array ['a', 'b', 'c']
        end
      end

      shared_examples "empty array" do
        it "returns an empty array" do
          expect(profile.groups).to eq []
        end
      end

      context "when groups and app_metadata.groups have elements" do
        let(:profile) { described_class.new(groups: ['a', 'b'], app_metadata: { groups: ['b', 'a', 'c'] }) }
        include_examples "union"
      end

      context "when groups is nil" do
        let(:profile) { described_class.new(app_metadata: { groups: ['a', 'b', 'c'] }) }
        include_examples "union"
      end

      context "when app_metadata.groups is nil" do
        let(:profile) { described_class.new(groups: ['a', 'b', 'c'], app_metadata: {}) }
        include_examples "union"
      end

      context "when app_metadata is nil" do
        let(:profile) { described_class.new(groups: ['a', 'b', 'c']) }
        include_examples "union"
      end

      context "when groups and app_metadata.groups are nil" do
        let(:profile) { described_class.new(app_metadata: {}) }
        include_examples "empty array"
      end

      context "when groups and app_metadata are nil" do
        let(:profile) { described_class.new({}) }
        include_examples "empty array"
      end
    end

    describe "#secondary_emails" do
      it "returns content of email_aliases" do
        profile = described_class.new({ email_aliases: ["one", "two"] })
        expect(profile.secondary_emails).to contain_exactly "one", "two"
      end

      it "is empty array when email_alises is empty" do
        profile = described_class.new({ email_aliases: [] })
        expect(profile.secondary_emails).to eq []
      end

      it "is empty array email_alises is nil" do
        profile = described_class.new({ })
        expect(profile.secondary_emails).to eq []
      end
    end
  end
end
