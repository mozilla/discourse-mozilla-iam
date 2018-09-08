module MozillaIAM
  Profile.class_eval do
    def duplicate_accounts
      taken_emails = get(:taken_emails)
      Array(taken_emails).map do |email|
        user = User.find_by_email(email)
        UserEmail.create(user: @user, email: email) unless user
        user unless user == @user
      end.uniq.compact
    end
  end
end
