require_relative "../iam_helper"

describe UsersController do
  let!(:user) { sign_in(Fabricate(:user, admin: true)) }
  let(:profile) { MozillaIAM::Profile.new(user, "uid") }

  describe '#create' do
    before do
      User.any_instance.stubs(:active?).returns(true)
    end

    let(:create_params) do
      get '/u/hp.json'
      json = JSON.parse(response.body)
      {
        name: "Jill Bloggs",
        username: "jillbloggs",
        password: "supersecret",
        email: "jill@example.com",
        password_confirmation: json["value"],
        challenge: json["challenge"].reverse
      }
    end

    context "without dinopark_enabled" do
      it "creates user as normal" do
        post "/u.json", params: create_params.merge({
          dinopark_enabled: false
        })
        expect(response.status).to eq 200
        expect(User.find(JSON.parse(response.body)["user_id"]).username).to eq "jillbloggs"
        expect(session[:authentication]&.[](:dinopark_enabled)).to be_nil
      end

      it "doesn't set show_dinopark_banner cookie" do
        post "/u.json", params: create_params.merge({
          dinopark_enabled: false
        })
        expect(response.status).to eq 200
        expect(cookies["show_dinopark_banner"]).to be_nil
      end
    end

    context "with dinopark_enabled" do
      it "creates user and sets dinopark_enabled flag in auth data" do
        post "/u.json", params: create_params.merge({
          dinopark_enabled: true
        })
        expect(response.status).to eq 200
        expect(User.find(JSON.parse(response.body)["user_id"]).username).to eq "jillbloggs"
        expect(session[:authentication]&.[](:dinopark_enabled)).to eq true
      end

      it "uses unique username if its taken" do
        Fabricate(:user, username: "jillbloggs")
        post "/u.json", params: create_params.merge({
          dinopark_enabled: true
        })
        expect(response.status).to eq 200
        expect(User.find(JSON.parse(response.body)["user_id"]).username).to eq "jillbloggs1"
        expect(session[:authentication]&.[](:dinopark_enabled)).to eq true
      end

      it "sets show_dinopark_banner cookie" do
        post "/u.json", params: create_params.merge({
          dinopark_enabled: true
        })
        expect(response.status).to eq 200
        expect(cookies["show_dinopark_banner"]).to be
      end
    end
  end

  describe '#username' do
    let(:new_username) { user.username + "_1" }

    context "without dinopark_enabled" do
      it "allows update to username" do
        put "/u/#{user.username}/preferences/username.json", params: { new_username: new_username }

        expect(response.status).to eq(200)
        expect(user.reload.username).to eq(new_username)
      end
    end

    context "with dinopark_enabled" do
      let(:old_username) { user.username }
      before do
        profile.dinopark_enabled = true
      end

      it "doesn't allow update to username" do
        put "/u/#{user.username}/preferences/username.json", params: { new_username: new_username }

        expect(response.status).to eq(422)
        expect(user.reload.username).to eq(old_username)
      end
    end

  end

  describe '#pick_avatar' do
    let(:upload) { Fabricate(:upload, user: user) }

    shared_examples "allows update to avatar" do
      it "allows update to avatar" do
        put "/u/#{user.username}/preferences/avatar/pick.json", params: {
          upload_id: upload.id, type: "custom"
        }

        expect(response.status).to eq(200)
        expect(user.reload.uploaded_avatar_id).to eq(upload.id)
      end
    end

    context "without dinopark_enabled" do
      include_examples "allows update to avatar"
    end

    context "with dinopark_enabled" do
      before do
        profile.dinopark_enabled = true
        SiteSetting.dinopark_avatars_enabled = true
      end

      it "doesn't allow update to avatar" do
        put "/u/#{user.username}/preferences/avatar/pick.json", params: {
          upload_id: upload.id, type: "custom"
        }

        expect(response.status).to eq(422)
        expect(user.reload.uploaded_avatar_id).to_not eq(upload.id)
      end

      context "with dinopark avatars disabled" do
        before do
          SiteSetting.dinopark_avatars_enabled = false
        end

        include_examples "allows update to avatar"
      end
    end
  end

  describe '#update' do
    let!(:old_email_level) { user.user_option.email_level }
    let(:update_params) do
      {
        name: "new name",
        title: "new title",
        bio_raw: "new bio",
        location: "new location",
        website: "http://new.website/",
        email_level: UserOption.email_level_types[:always]
      }
    end

    context "without dinopark_enabled" do
      it "allows update to synced fields" do
        put "/u/#{user.username}.json", params: update_params

        user.reload

        expect(user.name).to eq("new name")
        expect(user.title).to eq("new title")
        expect(user.user_profile.bio_raw).to eq("new bio")
        expect(user.user_profile.location).to eq("new location")
        expect(user.user_profile.website).to eq("http://new.website/")

        expect(user.user_option.email_level).to_not eq(old_email_level)
        expect(user.user_option.email_level).to eq(UserOption.email_level_types[:always])
      end
    end

    context "with dinopark_enabled" do
      let!(:old_name) { user.name }
      let!(:old_title) { user.title }
      let!(:old_bio) { user.user_profile.bio_raw }
      let!(:old_location) { user.user_profile.location }
      let!(:old_website) { user.user_profile.website }
      before do
        profile.dinopark_enabled = true
      end

      it "doesn't allow update to synced fields" do
        put "/u/#{user.username}.json", params: update_params

        user.reload

        expect(user.name).to eq(old_name)
        expect(user.title).to eq(old_title)
        expect(user.user_profile.bio_raw).to eq(old_bio)
        expect(user.user_profile.location).to eq(old_location)
        expect(user.user_profile.website).to eq(old_website)

        expect(user.user_option.email_level).to_not eq(old_email_level)
        expect(user.user_option.email_level).to eq(UserOption.email_level_types[:always])
      end
    end
  end
end
