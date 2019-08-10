require_relative '../../../iam_helper'

describe OmniAuth::Strategies::OAuth2 do

  before do
    OmniAuth::Strategies::Auth0.any_instance.stubs(:no_client_id?).returns(false)
    OmniAuth::Strategies::Auth0.any_instance.stubs(:no_client_secret?).returns(false)
    OmniAuth::Strategies::Auth0.any_instance.stubs(:no_domain?).returns(false)
    SiteSetting.enable_local_logins = false
  end

  it "redirects callback with no params back to login" do

    get '/auth/auth0/callback'

    expect(response.status).to eq(302)
    expect(response.location).to eq('/auth/auth0?prompt=login')
  end

  it "handles callbacks with params normally" do
    get '/auth/auth0/callback?param'

    expect(response.status).to eq(302)
    expect(response.location).to eq('/auth/failure?message=csrf_detected&strategy=auth0')
  end

  it "uses autologin and sign-up flow with normal authentication" do
    get '/auth/auth0'

    expect(response.status).to eq(302)
    expect(URI.parse(response.location).query).to_not include('prompt=login')
    expect(URI.parse(response.location).query).to include('action=signup')
  end

  it "passes prompt param through" do
    get '/auth/auth0?prompt=value'

    expect(response.status).to eq(302)
    expect(URI.parse(response.location).query).to include('prompt=value')
  end

  it "passes action param through" do
    get '/auth/auth0?action=value'

    expect(response.status).to eq(302)
    expect(URI.parse(response.location).query).to include('action=value')
  end

  it "doesn't pass params to redirect_uri sent to auth0" do
    get "/auth/auth0?param"
    query = CGI.parse URI.parse(response.location).query
    redirect_uri = query["redirect_uri"].first
    expect(redirect_uri).to_not include("/auth/auth0/callback?param")
    expect(redirect_uri).to eq "http://test.localhost/auth/auth0/callback"
  end

  it "redirects to original origin after failing callback in omniauth code" do
    origin = "https://discourse-site/t/1234"
    fail_url = "/auth/auth0/callback?code=fail&state=fail"

    get "/auth/auth0", headers: { "Referer" => origin }
    get fail_url
    get response.location
    expect(response.body).to include("/auth/auth0?origin=#{CGI.escape(origin)}")

    get "/auth/auth0?origin=#{origin}", headers: { "Referer" => fail_url }
    get '/auth/auth0/callback?code=succeed&state=succeed'
    expect(request.env["omniauth.origin"]).to_not eq fail_url
    expect(request.env["omniauth.origin"]).to eq origin
  end

  context "with omniauth test mode" do
    before do
      OmniAuth.config.test_mode = true
    end

    it "uses correct origin after failing callback in discourse code" do
      auth_result = Auth::Result.new
      auth_result.failed = true
      auth_result.failed_reason = "Oops, it failed!"
      MozillaIAM::Authenticator.any_instance.stubs(:after_authenticate).returns(auth_result)

      origin = "https://discourse-site/t/1234"

      get "/auth/auth0", headers: { "Referer" => origin }
      get "/auth/auth0/callback"
      expect(response.body).to include("/auth/auth0?origin=#{CGI.escape(origin)}")
    end

    after do
      OmniAuth.config.test_mode = false
    end
  end

end
