module MozillaIAM
  class Authenticator < Auth::OAuth2Authenticator
    def after_authenticate(auth_token)
      begin
        id_token = auth_token[:credentials][:id_token]
        payload, header =
          JWT.decode(
            id_token,
            aud: SiteSetting.auth0_client_id
          )

        logout_delay = payload['exp'].to_i - payload['iat'].to_i
        ::PluginStore.set('mozilla-iam', 'logout_delay', logout_delay)
        Rails.cache.write('mozilla-iam/logout_delay', logout_delay)

        auth_token[:session][:mozilla_iam] = {
          last_refresh: Time.now
        }

        result = Auth::Result.new

        result.email = email = payload['email']
        result.email_valid = email_valid = payload['email_verified']
        result.user = user = User.find_by_email(email) if email_valid
        result.name = payload['name']
        uid = payload['sub']
        result.extra_data = { uid: uid }

        if user
          Profile.new(user, uid).force_refresh
        end

        result
      rescue => e
        result = Auth::Result.new
        result.failed = true
        result.failed_reason = I18n.t("login.omniauth_error")
        Rails.logger.error("#{e.class} (#{e.message})\n#{e.backtrace.join("\n")}")
        return result
      end
    end

    def after_create_account(user, auth)
      uid = auth[:extra_data][:uid]
      Profile.new(user, uid).force_refresh
    end

    def register_middleware(omniauth)
      omniauth.provider(
        :auth0,
        SiteSetting.auth0_client_id,
        SiteSetting.auth0_client_secret,
        SiteSetting.auth0_domain,
        {
          authorize_params: {
            scope: 'openid name email'
          }
        }
      )
    end
  end
end
