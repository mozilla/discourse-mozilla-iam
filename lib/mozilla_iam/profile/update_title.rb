module MozillaIAM
  Profile.class_eval do
    during_refresh :update_title

    def update_title
      return unless dinopark_enabled?

      pronouns = attr(:pronouns)
      fun_title = attr(:fun_title)
      title = ""

      title << "(#{pronouns})" unless pronouns.blank?
      title << " " unless pronouns.blank? || fun_title.blank?
      title << fun_title unless fun_title.blank?

      @user.update(title: title) unless @user.title == title
    end
  end
end
