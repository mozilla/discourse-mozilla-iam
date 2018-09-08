module MozillaIAM

  module UserSerializerExtensions

    def duplicate_accounts
      Profile.for(object)&.duplicate_accounts&.map do |u|
        UserSerializer.new(u, scope: Guardian.new(u), root: false)
      end
    end

    def include_duplicate_accounts?
      (object&.id == scope.user&.id) || scope.is_admin?
    end

  end
end
