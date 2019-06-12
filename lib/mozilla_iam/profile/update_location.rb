module MozillaIAM
  Profile.class_eval do
    during_refresh :update_location

    def update_location
      return unless dinopark_enabled?

      location = attr(:location)
      return if @user.user_profile.location == location

      unless location.blank?
        @user.user_profile.update(location: location)
      else
        @user.user_profile.update(location: nil)
      end
    end
  end
end
