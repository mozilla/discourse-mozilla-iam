require_relative '../iam_helper'

describe MozillaIAM::Authenticator do

  before do
    OmniAuth::Strategies::Auth0.any_instance.stubs(:no_client_id?).returns(false)
    OmniAuth::Strategies::Auth0.any_instance.stubs(:no_client_secret?).returns(false)
    OmniAuth::Strategies::Auth0.any_instance.stubs(:no_domain?).returns(false)
    SiteSetting.enable_local_logins = false
    OmniAuth.config.test_mode = true
  end

  it "does all the right things on signup" do
    stub_jwks_request()
    OmniAuth.config.mock_auth[:auth0] = OmniAuth::AuthHash.new({
      credentials: {
        id_token: create_id_token({
          name: "Bob",
          username: "bob",
          email: "bob@example.com"
        }, {
          "https://sso.mozilla.com/claim/AAL": "MAXIMUM"
        })
      }
    })

    get "/auth/auth0"
    expect(response.location).to eq "http://test.localhost/auth/auth0/callback"
    get response.location
    expect(response.location).to eq "http://test.localhost/"
    get "/latest"

    stub_apis_profile_request(create_uid("bob"), {})

    get '/u/hp.json'
    hp = JSON.parse(response.body)
    post "/u.json", params: {
      name: "Bob",
      username: "bob",
      email: "bob@example.com",
      password_confirmation: hp["value"],
      challenge: hp["challenge"].reverse
    }

    expect(session[:mozilla_iam]).to be

    get "/latest"

    session_data = MozillaIAM::SessionData.find_or_create(session, cookies)
    expect(session_data.aal).to eq "MAXIMUM"

    auth_token = UserAuthToken.find(session_data.user_auth_token_id)
    expect(auth_token.user_id).to eq User.find_by_username("bob").id
  end

  after do
    OmniAuth.config.test_mode = false
  end

end
