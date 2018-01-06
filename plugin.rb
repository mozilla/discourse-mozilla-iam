# name: mozilla-iam
# about: A plugin to integrate Discourse with Mozilla's Identity and Access Management (IAM) system
# version: 0.2.5
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

register_asset "stylesheets/common/mozilla-iam.scss"

auth_provider(title: 'Mozilla',
              message: 'Log In / Sign Up',
              authenticator: MozillaIAM::Authenticator.new('auth0', trusted: true),
              full_screen_login: true)
