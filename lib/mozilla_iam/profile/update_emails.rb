module MozillaIAM
  Profile.class_eval do
    during_refresh :update_emails
    register_as_array :taken_emails

    private

    def store_taken_email_or_raise(e, taken_emails)
      raise e unless e.message == "Validation failed: Email has already been taken"
      taken_emails << e.record.email
    end

    def update_emails
      locale, I18n.locale = I18n.locale, :en
      emails = attr(:secondary_emails)
      taken_emails = []
      @user.user_emails.where(primary: false).where.not(email: emails).delete_all
      emails.each do |email|
        begin
          UserEmail.find_or_create_by!(user: @user, email: email)
        rescue ActiveRecord::RecordInvalid => e
          store_taken_email_or_raise(e, taken_emails)
        end
      end
      set(:taken_emails, taken_emails)
      I18n.locale = locale
    end
  end
end
