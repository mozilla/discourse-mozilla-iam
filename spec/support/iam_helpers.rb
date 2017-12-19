module IAMHelpers
  def private_key
    @private_key ||= OpenSSL::PKey::RSA.generate(2048)
  end

  def create_jwks
    public_key = private_key.public_key

    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = 0
    cert.not_before = Time.now
    cert.not_after = Time.now + 3600
    cert.public_key = public_key
    cert.sign(private_key, OpenSSL::Digest::SHA1.new)
    x5c = cert.to_s.lines[1..-2].join.gsub("\n", '')

    MultiJson.dump({
      keys: [
        {
          x5c: [
            x5c
          ],
          kid: 'the_best_key'
        }
      ]
    })
  end

  def stub_jwks_request
    stub_request(:get, 'https://auth.mozilla.auth0.com/.well-known/jwks.json')
      .to_return(status: 200, body: create_jwks)
  end

  def create_jwt(payload, header)
    JWT.encode(payload, private_key, 'RS256', header)
  end

  def create_id_token(user, additional_payload = {}, additional_header = {})
    payload = {
      name: user[:name],
      email: user[:email] || user.email,
      sub: create_uid(user[:username]),
      email_verified: true,
      iss: 'https://auth.mozilla.auth0.com/',
      aud: 'the_best_client_id',
      exp: Time.now.to_i + 7.days,
      iat: Time.now.to_i
    }.merge(additional_payload)

    header_fields = {
      kid: 'the_best_key'
    }.merge(additional_header)

    create_jwt(payload, header_fields)
  end

  def create_uid(username)
    "ad|Mozilla-LDAP|#{username}"
  end

  def authenticate_with_id_token(id_token)
    stub_jwks_request

    authenticator = MozillaIAM::Authenticator.new('auth0', trusted: true)
    authenticator.after_authenticate({
      credentials: {
        id_token: id_token
      },
      session: {}
    })
  end

  def authenticate_user(user)
    authenticate_with_id_token create_id_token(user)
  end

  def stub_oauth_token_request(aud)
    stub_jwks_request

    payload = {
      sub: 'the_best_client_id@clients',
      iss: 'https://auth.mozilla.auth0.com/',
      aud: aud,
      exp: Time.now.to_i + 7.days,
      iat: Time.now.to_i
    }

    header_fields = {
      kid: 'the_best_key'
    }

    access_token = JWT.encode(payload, private_key, 'RS256', header_fields)
    body = MultiJson.dump(access_token: access_token)

    stub_request(:post, 'https://auth.mozilla.auth0.com/oauth/token')
      .to_return(status: 200, body: body)
  end

  def stub_people_api_profile_request(uid, profile)
    stub_oauth_token_request('https://person-api.sso.mozilla.com')

    stub_request(:get, "https://uhbz4h3wa8.execute-api.us-west-2.amazonaws.com/prod/profile/#{uid}")
      .to_return(status: 200, body: MultiJson.dump(body: MultiJson.dump(profile)))
  end

  def stub_management_api_profile_request(uid, profile)
    stub_oauth_token_request('https://auth.mozilla.auth0.com/api/v2/')

    stub_request(:get, "https://auth.mozilla.auth0.com/api/v2/users/#{uid}?fields=app_metadata")
      .to_return(status: 200, body: MultiJson.dump(app_metadata: profile))
  end
end
