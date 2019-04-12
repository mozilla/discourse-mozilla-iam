module MozillaIAM
  class NotificationController < ActionController::Base

    def notification
      unless ["update", "delete"].include? params[:operation]
        return render body: "Unsupported operation", status: 200
      end
      begin
        token = request.headers["Authorization"].sub("Bearer ","")
        JWT.decode(
          token,
          aud: SiteSetting.mozilla_iam_notification_aud
        )
      rescue => e
        return render body: "Invalid JWT", status: 400
      end

      uid = params[:id]
      profile = Profile.find_by_uid(uid)
      profile&.force_refresh
      Rails.logger.info <<~EOF.gsub(/\n/, ", ")
        Mozilla IAM: Successfully refreshed profile for #{uid}
        operation: #{params[:operation]}, time: #{params[:time]}
        refresh time: #{Time.now.to_i}
      EOF
      render body: nil, status: 200
    end

  end
end
