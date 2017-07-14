require_relative '../iam_helper'

describe TopicsController do
  context '#check_iam_session' do
    it 'does nothing under 15 minutes' do
      user = Fabricate(:user)
      authenticate_user(user)
      log_in_user(user)

      last_refresh = Time.now - 14.minutes
      user.custom_fields['mozilla_iam_last_refresh'] = last_refresh
      session[:mozilla_iam] = { last_refresh: last_refresh }

      get :show, id: 666

      expect(session[:mozilla_iam][:last_refresh]).to be_within(5.seconds).of last_refresh
    end

    it 'refreshes the session after 15 minutes' do
      user = Fabricate(:user)
      authenticate_user(user)
      log_in_user(user)

      last_refresh = Time.now - 16.minutes
      user.custom_fields['mozilla_iam_last_refresh'] = last_refresh
      session[:mozilla_iam] = { last_refresh: last_refresh }

      get :show, id: 666
      expect(session[:mozilla_iam][:last_refresh]).to be_within(5.seconds).of Time.now
    end

    it 'logs off the user after 7 days' do
      user = Fabricate(:user)
      authenticate_user(user)
      log_in_user(user)

      last_refresh = Time.now - 8.days
      user.custom_fields['mozilla_iam_last_refresh'] = last_refresh
      session[:mozilla_iam] = { last_refresh: last_refresh }

      expect(session['current_user_id']).to be

      get :show, id: 666

      expect(session['current_user_id']).to be_nil
    end

    it 'logs off the user if an exception is thrown' do
      log_in

      session[:mozilla_iam] = { last_refresh: 'not a number' }
      expect(session['current_user_id']).to be

      get :show, id: 666 rescue
      expect(session['current_user_id']).to be_nil
    end
  end
end
