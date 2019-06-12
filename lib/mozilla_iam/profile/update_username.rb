module MozillaIAM
  Profile.class_eval do
    during_refresh :update_username

    def update_username
      return unless dinopark_enabled?

      username = attr(:username).dup
      return if username.blank?
      old_username = @user.username
      return if username == old_username

      username = UserNameSuggester.fix_username(username)
      return if username == old_username
      return if User.reserved_username? username

      if old_username.downcase != username.downcase
        username = UserNameSuggester.find_available_username_based_on(username, old_username)
      end

      unless @user.change_username(username)
        Rails.logger.error <<~EOF
          Mozilla IAM: Error updating username for user #{@user.id}
          current username: #{old_username}, new username: #{username}, dinopark username: #{attr(:username)}
        EOF
      end

      MessageBus.publish "/mozilla-iam/username-refresh", [old_username, username], user_ids: [@user.id]
    end
  end
end
