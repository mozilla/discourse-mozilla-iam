module MozillaIAM
  module ApplicationExtensions
    def check_iam_session
      begin
        last_refresh = session[:mozilla_iam].try(:[], :last_refresh)
        logout_delay =
          Rails.cache.fetch('mozilla-iam/logout_delay') do
            ::PluginStore.get('mozilla-iam', 'logout_delay')
          end

        return if last_refresh.nil? || !current_user
        if last_refresh + logout_delay < Time.now
          reset_session
          log_off_user
        else
          refresh_iam_session
        end
      rescue => e
        reset_session
        log_off_user
        raise e
      end
    end

    def refresh_iam_session
      session[:mozilla_iam][:last_refresh] = Profile.refresh(current_user)
    end
  end
end
