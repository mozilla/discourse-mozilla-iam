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

        custom_upload = @user&.user_avatar&.custom_upload
        old_origin = custom_upload&.origin
        if old_origin == picture
          @user.update_columns(uploaded_avatar_id: custom_upload.id)
          return
        end

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
