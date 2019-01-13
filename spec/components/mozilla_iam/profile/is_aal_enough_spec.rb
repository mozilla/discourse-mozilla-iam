require_relative '../../../iam_helper'

describe MozillaIAM::Profile do
  describe "#is_aal_enough?" do
    let(:user) { Fabricate(:user) }
    let(:profile) { MozillaIAM::Profile.new(user, "uid") }

    context "when a user is in no mapped groups" do
      before do
        profile.expects(:get).with(:in_mapped_groups).returns("f")
      end

      it "returns true with nil" do
        expect(profile.is_aal_enough?(nil)).to eq true
      end

      it "returns true with UNKNOWN" do
        expect(profile.is_aal_enough?("UNKNOWN")).to eq true
      end

      it "returns true with LOW" do
        expect(profile.is_aal_enough?("LOW")).to eq true
      end

      it "returns true with MEDIUM" do
        expect(profile.is_aal_enough?("MEDIUM")).to eq true
      end

      it "returns true with HIGH" do
        expect(profile.is_aal_enough?("HIGH")).to eq true
      end

      it "returns true with MAXIMUM" do
        expect(profile.is_aal_enough?("MAXIMUM")).to eq true
      end
    end

    shared_examples "MEDIUM required" do
      it "returns false with nil" do
        expect(profile.is_aal_enough?(nil)).to eq false
      end

      it "returns false with UNKNOWN" do
        expect(profile.is_aal_enough?("UNKNOWN")).to eq false
      end

      it "returns false with LOW" do
        expect(profile.is_aal_enough?("LOW")).to eq false
      end

      it "returns true with MEDIUM" do
        expect(profile.is_aal_enough?("MEDIUM")).to eq true
      end

      it "returns true with HIGH" do
        expect(profile.is_aal_enough?("HIGH")).to eq true
      end

      it "returns true with MAXIMUM" do
        expect(profile.is_aal_enough?("MAXIMUM")).to eq true
      end
    end

    context "when a user is in mapped groups" do
      before do
        profile.expects(:get).with(:in_mapped_groups).returns("t")
      end

      include_examples "MEDIUM required"
    end

    context "when a user is a moderator" do
      let(:user) { Fabricate(:moderator) }

      include_examples "MEDIUM required"
    end

    context "when a user is an admin" do
      let(:user) { Fabricate(:admin) }

      include_examples "MEDIUM required"
    end

  end
end
