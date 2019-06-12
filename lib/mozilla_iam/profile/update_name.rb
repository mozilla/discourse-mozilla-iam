module MozillaIAM
  Profile.class_eval do
    during_refresh :update_name

    def update_name
      return unless dinopark_enabled?

      full_name = attr(:full_name)
      unless full_name.blank?
        @user.update(name: full_name)
      else
        @user.update(name: "")
      end
    end
  end
end
