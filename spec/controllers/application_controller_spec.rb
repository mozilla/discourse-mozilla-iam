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

      expect(session[:mozilla_iam][:last_refresh]).to be_within(5.seconds).of last_refresh
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
      expect(session[:mozilla_iam][:last_refresh]).to be_within(5.seconds).of Time.now
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

    context "with no session[:mozilla_iam] set" do
      let(:user) { Fabricate(:user) }
      before do
        authenticate_user(user)
        log_in_user(user)
        session[:mozilla_iam] = nil
      end

      context "and with a user with a last refresh" do
        it "fetches last refresh from user profile" do
          last_refresh = Time.now - 5.minutes
          user.custom_fields['mozilla_iam_last_refresh'] = last_refresh
          user.save_custom_fields

          get :show, params: { id: 666 }, format: :json

          expect(session[:mozilla_iam][:last_refresh]).to be_within(2.seconds).of last_refresh
        end
      end

      context "and with a user with no last refresh" do
        it "sets session[:mozilla_iam][:no_refresh] to true" do
          user.custom_fields['mozilla_iam_last_refresh'] = nil
          user.save_custom_fields

          get :show, params: { id: 666 }, format: :json

          expect(session[:mozilla_iam][:no_refresh]).to eq true
        end
      end

      context "and with a user with no profile" do
        it "sets session[:mozilla_iam][:no_refresh] to true" do
          user.custom_fields['mozilla_iam_uid'] = nil
          user.save_custom_fields

          get :show, params: { id: 666 }, format: :json

          expect(session[:mozilla_iam][:no_refresh]).to eq true
        end
      end

      context "and when MEDIUM or above AAL required" do
        it "kills session" do
          MozillaIAM::Profile.any_instance.expects(:is_aal_enough?).with(nil).returns(true)

          get :show, params: { id: 666 }, format: :json
          expect(session['current_user_id']).to be

          MozillaIAM::Profile.any_instance.expects(:is_aal_enough?).with(nil).returns(false)

          get :show, params: { id: 666 }, format: :json
          expect(session['current_user_id']).to be_nil
        end
      end
    end

    context "with session[:mozilla_iam][:no_refresh] set to true" do
      let(:user) { Fabricate(:user) }
      before do
        authenticate_user(user)
        log_in_user(user)
        session[:mozilla_iam] = { no_refresh: true }
      end

      it "doesn't query user profile" do
        MozillaIAM::Profile.expects(:for).never

        get :show, params: { id: 666 }, format: :json
      end

      it "doesn't refresh user profile" do
        MozillaIAM::Profile.expects(:refresh).never

        get :show, params: { id: 666 }, format: :json
      end

      context "and with session[:mozilla_iam][:last_refresh] set" do
        before do
          last_refresh = Time.now - 5.minutes
          session[:mozilla_iam][:last_refresh] = last_refresh
        end

        it "refreshes user profile" do
          MozillaIAM::Profile.expects(:refresh).once

          get :show, params: { id: 666 }, format: :json
        end
      end
    end

    context "when the AAL becomes too low" do
      it "kills session" do
        user = Fabricate(:user)
        authenticate_user(user)
        log_in_user(user)
        session[:mozilla_iam] = { aal: "LOW" }

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
