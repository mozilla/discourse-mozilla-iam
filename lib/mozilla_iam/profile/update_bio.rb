module MozillaIAM
  Profile.class_eval do
    during_refresh :update_bio

    def update_bio
      return unless dinopark_enabled?

      bio = attr(:description)
      return if @user.user_profile.bio_raw == bio

      unless bio.blank?
        @user.user_profile.update(bio_raw: bio)
      else
        @user.user_profile.update(bio_raw: nil)
      end
    end
  end
end
