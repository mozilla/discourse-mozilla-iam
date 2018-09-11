UserSerializer.attributes :secondary_emails
UserSerializer.send :alias_method, :include_secondary_emails?, :include_email?

class MozillaIAM::DuplicateAccountsUserSerializer < BasicUserSerializer
  attributes :email, :secondary_emails
end

UserSerializer.include MozillaIAM::SerializerExtensions::DuplicateAccounts
UserSerializer.has_many :duplicate_accounts,
  embed: :object,
  serializer: MozillaIAM::DuplicateAccountsUserSerializer

UserSerializer.include MozillaIAM::SerializerExtensions::MozillaIAM
