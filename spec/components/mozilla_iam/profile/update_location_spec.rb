require_relative '../../../iam_helper'

describe MozillaIAM::Profile do

  shared_context "shared context" do
    before do
      user.user_profile.update(location: "Default location")
    end
    let!(:location_before) { user.user_profile.location }
  end

  shared_context "with attribute already set" do
    before do
      profile.expects(:attr).with(:location).returns(location_before)
      user.user_profile.expects(:update).never
    end
  end

  shared_examples "no change" do
    it "does nothing" do
      profile.send(:update_location)
      user.reload
      expect(user.user_profile.location).to eq location_before
    end
  end

  shared_examples "undefines" do
    it "makes the user's location blank" do
      profile.send(:update_location)
      user.reload
      expect(user.user_profile.location).to eq nil
    end
  end

  shared_examples "with dinopark_enabled? set to true" do
    context "with a dinopark location" do
      before do
        profile.expects(:attr).with(:location).returns("London, UK")
      end

      it "updates the user's location" do
        profile.send(:update_location)
        user.reload
        expect(user.user_profile.location).to eq "London, UK"
      end

    end
  end

  include_examples "dinopark refresh method", :update_location, :location
end
