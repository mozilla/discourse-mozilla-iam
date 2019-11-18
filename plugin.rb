# name: mozilla-iam
# about: A plugin to integrate Discourse with Mozilla's Identity and Access Management (IAM) system
# version: 1.6.2
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

register_svg_icon "external-link-alt"

auth_provider(title: 'Mozilla',
              message: 'Log In / Sign Up',
              authenticator: MozillaIAM::Authenticator.new('auth0', trusted: true),
              full_screen_login: true)

after_initialize do
  User.register_custom_field_type "mozilla_iam_dinopark_enabled", :boolean
  User.register_custom_field_type "mozilla_iam_never_show_dinopark_modal", :boolean
end
