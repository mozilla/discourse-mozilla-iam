require_relative "../../iam_helper"

describe Auth::Result do
  describe "#to_client_hash" do
    let(:result) do
      result = described_class.new
      result.email = "janebloggs@example.com"
      result.username = "janebloggs"
      result.extra_data = { uid: "uid" }
      result
    end
    let(:hash) { result.to_client_hash }
    let(:profile) { MozillaIAM::API::PersonV2::Profile.new({}) }

    shared_examples "does nothing" do
      it "doesn't include dinopark_profile attribute" do
        expect(hash[:username]).to eq "janebloggs"
        expect(hash[:dinopark_profile]).to be_nil
      end
    end

    context "with dinopark_access" do

      before do
        MozillaIAM::API::PersonV2.any_instance.expects(:profile).with("uid").returns(profile)
        result.extra_data[:dinopark_access] = true
      end

      context "without person v2 profile" do
        before do
          profile.expects(:blank?).returns(true)
        end

        include_examples "does nothing"
      end

      context "with person v2 profile" do
        before do
          profile.expects(:blank?).returns(false)
          profile.expects(:to_hash).returns({
            username: "janebloggs"
          })
        end

        it "includes dinopark_profile attribute" do
          expect(hash[:username]).to eq "janebloggs"
          expect(hash[:dinopark_profile][:username]).to eq "janebloggs"
        end
      end

    end

    context "without dinopark_access" do
      before do
        MozillaIAM::API::PersonV2.any_instance.expects(:profile).never
        result.extra_data[:dinopark_access] = false
      end

      include_examples "does nothing"
    end
  end
end
