require_relative 'mozilla_iam/engine'

require_relative 'mozilla_iam/serializer_extensions/duplicate_accounts'
require_relative 'mozilla_iam/serializer_extensions/mozilla_iam'
require_relative 'mozilla_iam/api'
require_relative 'mozilla_iam/api/oauth'
require_relative 'mozilla_iam/api/person'
require_relative 'mozilla_iam/api/person_v2'
require_relative 'mozilla_iam/api/management'
require_relative 'mozilla_iam/application_extensions'
require_relative 'mozilla_iam/authenticator'
require_relative 'mozilla_iam/jwks'
require_relative 'mozilla_iam/jwt'
require_relative 'mozilla_iam/profile'
require_relative 'mozilla_iam/omniauth_oauth2_extensions'

module MozillaIAM
end
