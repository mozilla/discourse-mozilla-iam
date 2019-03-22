module MozillaIAM
  Profile.class_eval do
    def dinopark_enabled?
      if get("dinopark_enabled") === "t" ||
         get("dinopark_enabled") === true
        return true
      else
        return false
      end
    end

    def dinopark_enabled=(enabled)
      set("dinopark_enabled", enabled)
    end
  end
end
