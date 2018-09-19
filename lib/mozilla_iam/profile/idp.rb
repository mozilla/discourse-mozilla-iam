module MozillaIAM
  Profile.class_eval do
    def idp
      case get("uid")
      when /^ad\|Mozilla-LDAP/
        "LDAP"
      when /^oauth2\|firefoxaccounts\|/
        "Firefox"
      when /^github\|/
        "GitHub"
      when /^google-oauth2\|/
        "Google"
      when /^email\|/
        "Email"
      else
        "Unknown"
      end
    end
  end
end
