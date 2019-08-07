# frozen_string_literal: true

require_relative '../../iam_helper'

describe MozillaIAM::DinoparkLinkController, type: :request do

  describe "#link" do
    let(:user) { Fabricate(:user) }
    let!(:profile) { MozillaIAM::Profile.new(user, "uid") }
    let!(:last_refresh) { Time.now - 5.minutes }

    before do
      user.custom_fields["mozilla_iam_last_refresh"] = last_refresh
      user.save_custom_fields
    end

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

    it "doesn't let an unauthenticated user link" do
      post "/mozilla_iam/dinopark_link.json"

      expect(response.status).to eq 403
      expect(JSON.parse(response.body)["error_type"]).to eq "not_logged_in"
    end

    it "fails without CSRF token" do
      ActionController::Base.allow_forgery_protection = true
      post "/mozilla_iam/dinopark_link.json"
      expect(response.status).to eq 403
      expect(JSON.parse(response.body)).to eq ["BAD CSRF"]
      ActionController::Base.allow_forgery_protection = false
    end

  end
end
