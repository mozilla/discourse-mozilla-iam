# name: mozilla-iam
# about: A plugin to integrate Discourse with Mozilla's Identity and Access Management (IAM) system
# version: 0.1.2
# authors: Leo McArdle
# url: https://github.com/mozilla/discourse-mozilla-iam

gem 'omniauth-auth0', '2.0.0'

require 'jwt'
require 'faraday'
require 'multi_json'
require 'base64'
require 'openssl'

require 'auth/oauth2_authenticator'

require_relative 'lib/mozilla_iam'

add_admin_route 'mozilla_iam.mappings.title', 'mozilla-iam.mappings'

auth_provider(title: 'Mozilla',
              message: 'Log In / Sign Up',
              authenticator: MozillaIAM::Authenticator.new('auth0', trusted: true),
              full_screen_login: true)

after_initialize do

  add_to_serializer(:AdminDetailedUser, :mozilla_iam, false) do
    object.custom_fields.select do |k, v|
      k.start_with?('mozilla_iam')
    end.map do |k, v|
      [k.sub('mozilla_iam_', ''), v]
    end.to_h
  end

end
