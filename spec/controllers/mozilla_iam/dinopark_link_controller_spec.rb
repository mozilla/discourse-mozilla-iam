# frozen_string_literal: true

require_relative '../../iam_helper'

describe MozillaIAM::DinoparkLinkController, type: :request do
  let(:user) { Fabricate(:user) }
  let!(:profile) { MozillaIAM::Profile.new(user, "uid") }
  let!(:last_refresh) { Time.now - 5.minutes }

  before do
    user.custom_fields["mozilla_iam_last_refresh"] = last_refresh
    user.save_custom_fields
  end

  shared_examples "errors" do |url|
    it "doesn't let an unauthenticated user link" do
      post url
      expect(response.status).to eq 403
      expect(JSON.parse(response.body)["error_type"]).to eq "not_logged_in"
    end

    it "fails without CSRF token" do
      ActionController::Base.allow_forgery_protection = true
      post url
      expect(response.status).to eq 403
      expect(JSON.parse(response.body)).to eq ["BAD CSRF"]
      ActionController::Base.allow_forgery_protection = false
    end
  end

  describe "#link" do
    it "lets a user link themselves" do
      authenticate_user(user)
      sign_in(user)

      expect(profile.last_refresh).to be_within(5.seconds).of last_refresh
      expect(profile.dinopark_enabled?).to eq false

      stub_apis_profile_request("uid", {})
      MozillaIAM::SessionData.expects(:find_or_create).returns(MozillaIAM::SessionData.create(
        user_auth_token_id: 0,
        last_refresh: last_refresh,
        aal: "LOW"
      ))

      post "/mozilla_iam/dinopark_link.json"

      expect(response.status).to eq 200
      profile.reload
      expect(profile.dinopark_enabled?).to eq true
      expect(profile.last_refresh).to be_within(5.seconds).of Time.now
    end

    include_examples "errors", "/mozilla_iam/dinopark_link.json"
  end

  describe "#unlink" do
    before do
      user.custom_fields["mozilla_iam_dinopark_enabled"] = true
      user.save_custom_fields
    end

    it "lets a user unlink themselves" do
      uid = create_uid(user.username)
      stub_apis_profile_request(uid, {})
      stub_person_api_v2_profile_request(uid, person_v2_profile_with(
        primary_username: user.username,
        fun_title: "the builder",
        location: "Bobsville"
      ))
      authenticate_with_id_token create_id_token(user)
      sign_in(user)

      expect(profile.last_refresh).to be_within(5.seconds).of last_refresh
      expect(profile.dinopark_enabled?).to eq true
      user.reload
      expect(user.title).to eq "the builder"
      expect(user.user_profile.website).to eq "https://people.mozilla.org/p/#{user.username}"
      expect(user.user_profile.location).to eq "Bobsville"

      MozillaIAM::SessionData.expects(:find_or_create).returns(MozillaIAM::SessionData.create(
        user_auth_token_id: 0,
        last_refresh: last_refresh,
        aal: "LOW"
      ))

      post "/mozilla_iam/dinopark_unlink.json"

      expect(response.status).to eq 200
      profile.reload
      expect(profile.dinopark_enabled?).to eq false
      expect(profile.last_refresh).to be_within(5.seconds).of Time.now
      user.reload
      expect(user.title).to be_blank
      expect(user.user_profile.website).to be_blank
      expect(user.user_profile.location).to eq "Bobsville"
    end

    include_examples "errors", "/mozilla_iam/dinopark_unlink.json"
  end

  describe "#dont_show" do
    it "sets never_show_dinopark_modal flag" do
      expect(profile.send(:get, :never_show_dinopark_modal)).to eq nil
      authenticate_user(user)
      sign_in(user)

      post "/mozilla_iam/dinopark_link/dont_show.json"

      expect(response.status).to eq 200
      profile.reload
      expect(profile.send(:get, :never_show_dinopark_modal)).to eq true
    end
  end

end
