require_relative '../../../iam_helper'

describe MozillaIAM::Profile do

  shared_context "shared context" do
    before do
      user.user_profile.update!(website: "http://example.com")
    end
    let!(:website_before) { user.user_profile.website }
  end

  shared_context "with attribute already set" do
    before do
      profile.expects(:attr).with(:profile_url).returns(website_before)
    end
  end

  shared_examples "no change" do
    it "does nothing" do
      profile.send(:update_website)
      user.reload
      expect(user.user_profile.website).to eq website_before
    end
  end

  shared_examples "undefines" do
    it "makes the user's website blank" do
      profile.send(:update_website)
      user.reload
      expect(user.user_profile.website).to eq nil
    end
  end

  shared_examples "with dinopark_enabled? set to true" do
    context "with a dinopark profile_url" do
      before do
        profile.expects(:attr).with(:profile_url).returns("https://people.mozilla.org/u/bruce")
      end

      it "updates the user's website" do
        profile.send(:update_website)
        user.reload
        expect(user.user_profile.website).to eq "https://people.mozilla.org/u/bruce"
      end

    end
  end

  include_examples "dinopark refresh method", :update_website, :profile_url
end
