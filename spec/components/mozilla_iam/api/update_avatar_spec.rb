require_relative '../../../iam_helper'

describe MozillaIAM::Profile do

  shared_context "shared context" do
    before do
      upload = Fabricate(:upload)
      user.update!(uploaded_avatar_id: upload.id)
      user.user_avatar.update_columns(custom_upload_id: upload.id)
      stub_request(:get, "http://example.com/avatar.png")
        .to_return(status: 200, body: file_from_fixtures("logo.png"), headers: {})
    end
    let!(:avatar_before) { user.user_avatar.custom_upload }
  end

  shared_context "with attribute already set" do
    before do
      UserAvatar.expects(:import_url_for_user).never
      user.user_avatar.custom_upload.update_columns(origin: "http://example.com/avatar.png")
      profile.expects(:attr).with(:picture).returns("http://example.com/avatar.png")
    end
  end

  shared_examples "no change" do
    it "does nothing" do
      profile.send(:update_avatar)
      user.reload
      avatar_after = user.user_avatar.custom_upload
      expect(avatar_after.id).to eq avatar_before.id
      expect(avatar_after.origin).to eq avatar_before.origin
    end
  end

  shared_examples "undefines" do
    it "removes the user's avatar" do
      profile.send(:update_avatar)
      user.reload
      expect(user.user_avatar.custom_upload_id).to be_nil
    end
  end

  shared_examples "with dinopark_enabled? set to true" do
    context "with a dinopark picture" do
      before do
        profile.expects(:attr).with(:picture).returns("http://example.com/avatar.png")
      end

      it "updates the user's avatar" do
        profile.send(:update_avatar)
        user.reload
        expect(user.user_avatar.custom_upload.origin).to eq "http://example.com/avatar.png"
      end

    end

    context "with a dinopark picture which returns an invalid status code" do
      before do
        profile.expects(:attr).with(:picture).returns("http://example.com/404.png")
        stub_request(:get, "http://example.com/404.png")
          .to_return(status: 404, body: "", headers: {})
      end

      include_examples "undefines"
    end
  end

  include_examples "dinopark refresh method", :update_avatar, :picture
end
