module MozillaIAM
  class DinoParkPictureUpdateError < StandardError
  end

  Profile.class_eval do
    during_refresh :update_avatar

    def update_avatar
      return unless dinopark_enabled?

      picture = attr(:picture)
      begin
        raise DinoParkPictureUpdateError if picture.blank?

        old_origin = @user&.user_avatar&.custom_upload&.origin
        return if old_origin == picture

        raise DinoParkPictureUpdateError unless UserAvatar.import_url_for_user(picture, @user)
      rescue DinoParkPictureUpdateError
        Rails.logger.error <<~EOF
          Mozilla IAM: Error updating avatar for user #{@user.id}
          current avatar url: #{old_origin}, new avatar url: #{picture}
        EOF
        @user&.user_avatar&.custom_upload&.destroy!
      end
    end
  end
end
