module MozillaIAM
  module ApplicationExtensions
    def check_iam_session
      begin
        return unless current_user
        return if current_user.id < 0

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
          raise <<~EOF
            Mozilla IAM: User session expired
            user_id: #{current_user.id}, last_refresh: #{last_refresh}, logout_delay: #{logout_delay}
          EOF
        else
          refresh_iam_session
          aal = session[:mozilla_iam].try(:[], :aal)
          unless Profile.for(current_user).is_aal_enough?(aal)
            raise <<~EOF
              Mozilla IAM: AAL not enough, user logged out
              user_id: #{current_user.id}, aal: #{aal},
              session: #{session.to_hash}
            EOF
          end
        end
      rescue => e
        Rails.logger.warn("Killed session for user #{current_user.id}: #{e.class} (#{e.message})\n#{e.backtrace.join("\n")}")
        reset_session
        log_off_user
      end
    end

    def refresh_iam_session
      session[:mozilla_iam][:last_refresh] = Profile.refresh(current_user)
    end
  end
end
