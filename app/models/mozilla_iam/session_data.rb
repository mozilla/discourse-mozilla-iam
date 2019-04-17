module MozillaIAM
  class SessionData < ActiveRecord::Base

    TOKEN_COOKIE = Auth::DefaultCurrentUserProvider::TOKEN_COOKIE

    def self.find_or_create(session, cookies)
      auth_token = cookies[TOKEN_COOKIE]
      user_token = UserAuthToken.lookup(auth_token)

      if session[:mozilla_iam]
        session_data = create!(
          user_auth_token_id: user_token.id,
          last_refresh: session[:mozilla_iam][:last_refresh],
          aal: session[:mozilla_iam][:aal]
        )

        session.delete(:mozilla_iam)
        session_data
      else
        user_token.mozilla_iam_session_data
      end
    end
  end
end
