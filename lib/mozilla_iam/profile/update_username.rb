module MozillaIAM
  Profile.class_eval do
    during_refresh :update_username

    def update_username
      return unless dinopark_enabled?

      username = attr(:username).dup
      return if username.blank?
      return if username == @user.username

      username = UserNameSuggester.fix_username(username)
      return if username == @user.username
      return if User.reserved_username? username

      if @user.username.downcase != username.downcase
        username = UserNameSuggester.find_available_username_based_on(username, @user.username)
      end

      unless @user.change_username(username)
        Rails.logger.error <<~EOF
          Mozilla IAM: Error updating username for user #{@user.id}
          current username: #{@user.username}, new username: #{username}, dinopark username: #{attr(:username)}
        EOF
      end
    end
  end
end
