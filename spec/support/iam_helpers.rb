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
      iat: Time.now.to_i,
      "https://sso.mozilla.com/claim/groups": ["everyone"],
      "https://sso.mozilla.com/claim/AAL": "UNKNOWN"
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
    MozillaIAM::Profile.stubs(:refresh_methods).returns([])
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

    req_body = {
      audience: aud,
      client_id: "the_best_client_id",
      client_secret: "",
      grant_type: "client_credentials"
    }

    access_token = JWT.encode(payload, private_key, 'RS256', header_fields)
    res_body = MultiJson.dump(access_token: access_token)

    stub_request(:post, 'https://auth.mozilla.auth0.com/oauth/token')
      .with(body: req_body)
      .to_return(status: 200, body: res_body)
  end

  def stub_people_api_profile_request(uid, profile)
    stub_oauth_token_request('https://person-api.sso.mozilla.com')

    stub_request(:get, "https://person-api.sso.mozilla.com/v1/profile/#{uid}")
      .to_return(status: 200, body: MultiJson.dump(body: MultiJson.dump(profile)))
  end

  def stub_person_api_v2_profile_request(uid, profile)
    stub_oauth_token_request('api.sso.mozilla.com')

    stub_request(:get, "https://person.api.sso.mozilla.com/v2/user/user_id/#{uid}")
      .to_return(status: 200, body: MultiJson.dump(profile))
  end

  def single_attribute(value=nil, metadata={})
    metadata[:verified] = true if metadata[:verified].nil?
    metadata[:public] = true if metadata[:public].nil?
    {
      metadata: {
        verified: metadata[:verified],
        display: metadata[:public] ? "public" : "staff"
      },
      value: value
    }
  end

  def person_v2_profile_with(attributes, value=nil, metadata={})
    raw = {}
    if attributes.is_a? Hash
      attributes.each do |name, value|
        raw[name] = single_attribute(value)
      end
    else
      raw[attributes] = single_attribute(value, metadata)
    end
    raw
  end

  def stub_management_api_profile_request(uid, profile)
    stub_oauth_token_request('https://auth.mozilla.auth0.com/api/v2/')

    stub_request(:get, "https://auth.mozilla.auth0.com/api/v2/users/#{uid}")
      .to_return(status: 200, body: MultiJson.dump(profile))
  end

  def remove_consts(consts, parent = Object)
    consts.each do |const|
      parent.send(:remove_const, const)
      expect { parent.const_get(const) }.to raise_error(NameError)
    end
  end

  def stub_apis_profile_request(uid, profile)
    stub_management_api_profile_request(uid, profile)
    stub_people_api_profile_request(uid, profile)
  end
end
