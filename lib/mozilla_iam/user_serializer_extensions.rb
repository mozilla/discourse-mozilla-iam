module MozillaIAM

  module UserSerializerExtensions

    def duplicate_accounts
      Array(Profile.for(object)&.duplicate_accounts)
    end

    def include_duplicate_accounts?
      (object&.id == scope.user&.id) || scope.is_admin?
    end

  end
end
