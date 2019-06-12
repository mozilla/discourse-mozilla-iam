require_relative '../../../iam_helper'

describe MozillaIAM::Profile do

  shared_context "shared context" do
    before do
      user.user_profile.update(bio_raw: "Default description")
    end
    let!(:bio_before) { user.user_profile.bio_raw }
    let!(:bio_cooked_before) { user.user_profile.bio_cooked }
  end

  shared_context "with attribute already set" do
    before do
      profile.expects(:attr).with(:description).returns(bio_before)
      user.user_profile.expects(:update).never
    end
  end

  shared_examples "no change" do
    it "does nothing" do
      profile.send(:update_bio)
      user.reload
      expect(user.user_profile.bio_raw).to eq bio_before
      expect(user.user_profile.bio_cooked).to eq bio_cooked_before
    end
  end

  shared_examples "undefines" do
    it "makes the user's bio blank" do
      profile.send(:update_bio)
      user.reload
      expect(user.user_profile.bio_raw).to eq nil
      expect(user.user_profile.bio_cooked).to eq nil
    end
  end

  shared_examples "with dinopark_enabled? set to true" do
    context "with a dinopark description" do
      before do
        profile.expects(:attr).with(:description).returns("This is a description of who I am")
      end

      it "updates the user's bio" do
        profile.send(:update_bio)
        user.reload
        expect(user.user_profile.bio_raw).to eq "This is a description of who I am"
        expect(user.user_profile.bio_cooked).to eq "<p>This is a description of who I am</p>"
      end

    end
  end

  include_examples "dinopark refresh method", :update_bio, :description
end
