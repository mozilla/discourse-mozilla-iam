module MozillaIAM
  Profile.class_eval do
    def is_aal_enough?(aal)
      aal_levels = [
        "UNKNOWN",
        "LOW",
        "MEDIUM",
        "HIGH",
        "MAXIMUM"
      ]
      level = aal_levels.index(aal)
      level = aal_levels.index("UNKNOWN") if !level

      if get(:in_mapped_groups) == "t"
        level >= aal_levels.index("MEDIUM")
      elsif @user.moderator
        level >= aal_levels.index("MEDIUM")
      elsif @user.admin
        level >= aal_levels.index("MEDIUM")
      else
        true
      end
    end
  end
end
