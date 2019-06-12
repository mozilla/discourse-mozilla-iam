module MozillaIAM
  Profile.class_eval do
    during_refresh :update_website

    def update_website
      return unless dinopark_enabled?

      profile_url = attr(:profile_url)
      return if @user.user_profile.website == profile_url

      if profile_url.blank?
        @user.user_profile.update(website: nil)
      else
        @user.user_profile.update(website: profile_url)
      end
    end
  end
end
