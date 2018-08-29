module MozillaIAM
  module ApplicationExtensions
    def check_iam_session
      begin
        return unless current_user

        last_refresh = session[:mozilla_iam].try(:[], :last_refresh)
        no_refresh = session[:mozilla_iam].try(:[], :no_refresh)

        return if no_refresh && !last_refresh

        unless last_refresh
          current_user.clear_custom_fields
          last_refresh = Profile.for(current_user)&.last_refresh
          session[:mozilla_iam] = {} if session[:mozilla_iam].nil?
          if last_refresh
            session[:mozilla_iam][:last_refresh] = last_refresh
          else
            session[:mozilla_iam][:no_refresh] = true
            return
          end
        end

        logout_delay =
          Rails.cache.fetch('mozilla-iam/logout_delay') do
            ::PluginStore.get('mozilla-iam', 'logout_delay')
          end

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
