require_relative '../iam_helper'

describe TopicsController do
  context '#check_iam_session' do
    it 'does nothing under 15 minutes' do
      user = Fabricate(:user)
      authenticate_user(user)
      log_in_user(user)

      last_refresh = Time.now - 14.minutes
      user.custom_fields['mozilla_iam_last_refresh'] = last_refresh
      user.save_custom_fields
      session[:mozilla_iam] = { last_refresh: last_refresh }

      get :show, params: { id: 666 }, format: :json

      session_data = MozillaIAM::SessionData.find_or_create({}, request.cookies)
      expect(session_data.last_refresh).to be_within(5.seconds).of last_refresh
    end

    it 'refreshes the session after 15 minutes' do
      user = Fabricate(:user)
      authenticate_user(user)
      log_in_user(user)

      last_refresh = Time.now - 16.minutes
      user.custom_fields['mozilla_iam_last_refresh'] = last_refresh
      user.save_custom_fields
      session[:mozilla_iam] = { last_refresh: last_refresh }

      get :show, params: { id: 666 }, format: :json

      session_data = MozillaIAM::SessionData.find_or_create({}, request.cookies)
      expect(session_data.last_refresh).to be_within(5.seconds).of Time.now
    end

    it 'logs off the user after 7 days' do
      user = Fabricate(:user)
      authenticate_user(user)
      log_in_user(user)

      last_refresh = Time.now - 8.days
      user.custom_fields['mozilla_iam_last_refresh'] = last_refresh
      user.save_custom_fields
      session[:mozilla_iam] = { last_refresh: last_refresh }

      expect(session['current_user_id']).to be

      get :show, params: { id: 666 }, format: :json

      expect(session['current_user_id']).to be_nil
    end

    it 'logs off the user if an exception is thrown' do
      log_in

      session[:mozilla_iam] = { last_refresh: 'not a number' }
      expect(session['current_user_id']).to be

      get :show, params: { id: 666 }, format: :json rescue
      expect(session['current_user_id']).to be_nil
    end

    context "with no last_refresh" do
      it "kills session" do
        user = Fabricate(:user)
        authenticate_user(user)
        log_in_user(user)
        session[:mozilla_iam] = {}

        get :show, params: { id: 666 }, format: :json
        expect(session['current_user_id']).to be_nil
      end
    end

    context "when the AAL becomes too low" do
      it "kills session" do
        user = Fabricate(:user)
        authenticate_user(user)
        log_in_user(user)
        session[:mozilla_iam] = { last_refresh: Time.now, aal: "LOW" }

        MozillaIAM::Profile.any_instance.expects(:is_aal_enough?).with("LOW").returns(true)

        get :show, params: { id: 666 }, format: :json
        expect(session['current_user_id']).to be

        MozillaIAM::Profile.any_instance.expects(:is_aal_enough?).with("LOW").returns(false)

        get :show, params: { id: 666 }, format: :json
        expect(session['current_user_id']).to be_nil
      end
    end

    context "with system user" do
      let(:user) { User.find(-1) }
      before do
        authenticate_user(user)
        log_in_user(user)
      end

      it "does nothing" do
        MozillaIAM::Profile.expects(:for).never
        MozillaIAM::Profile.expects(:refresh).never

        get :show, params: { id: 666 }, format: :json
      end
    end
  end
end
