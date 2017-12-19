require_relative "../../iam_helper"

describe MozillaIAM::API do
  let(:config) do
    return {
      client_id: "abc",
      client_secret: "def",
      token_endpoint: "https://example.com/oauth/token",
      url: "https://example.com/api",
      aud: "example.com"
    }
  end

  let(:api) { MozillaIAM::API.new(config) }

  context "#initialize" do
    before do
      SiteSetting.auth0_client_id = "xyz"
      SiteSetting.auth0_client_secret = "zyx"
      SiteSetting.auth0_domain = "foobar.com"
    end

    it "uses config options" do
      expect(api.instance_variable_get(:@client_id)).to eq config[:client_id]
      expect(api.instance_variable_get(:@client_secret)).to eq config[:client_secret]
      expect(api.instance_variable_get(:@token_endpoint)).to eq config[:token_endpoint]
      expect(api.instance_variable_get(:@url)).to eq config[:url]
      expect(api.instance_variable_get(:@aud)).to eq config[:aud]
    end

    it "uses default options if none are set" do
      config = {
        url: "https://example.com/api",
        aud: "example.com"
      }
      api = MozillaIAM::API.new(config)

      expect(api.instance_variable_get(:@client_id)).to eq SiteSetting.auth0_client_id
      expect(api.instance_variable_get(:@client_secret)).to eq SiteSetting.auth0_client_secret
      expect(api.instance_variable_get(:@token_endpoint)).to eq "https://#{SiteSetting.auth0_domain}/oauth/token"
      expect(api.instance_variable_get(:@url)).to eq config[:url]
      expect(api.instance_variable_get(:@aud)).to eq config[:aud]
    end

    it "throws error if url isn't specified" do
      config = { aud: "example.com" }
      expect { MozillaIAM::API.new(config) }.to raise_error "no url in config"
    end

    it "throws error if aud isn't specified" do
      config = { url: "https://example.com/api" }
      expect { MozillaIAM::API.new(config) }.to raise_error "no aud in config"
    end
  end

  context "#get" do
    let(:res_success) { return { status: 200, body: '{"success":"true"}' } }

    before do
      api.expects(:access_token).returns('supersecret')
    end

    it "should get the right path" do
      stub_request(:get, "https://example.com/api/right_path").to_return(res_success)
      expect(api.send(:get, "right_path")[:success]).to eq "true"
    end

    it "should set the Authorization header" do
      stub_request(:get, "https://example.com/api/").with(headers: {
        "Authorization": "Bearer supersecret"
        }).to_return(res_success)
        expect(api.send(:get, "")[:success]).to eq "true"
    end

    it "should send parameters" do
      stub_request(:get, "https://example.com/api/?foo=bar").to_return(res_success)
      expect(api.send(:get, "", foo: 'bar')[:success]).to eq "true"
    end

    it "should return an empty hash if the the status code isn't 200" do
      stub_request(:get, "https://example.com/api/").to_return(status: 403)
      expect(api.send(:get, "")).to eq({})
    end
  end

  context "#access_token" do
    before do
      api.stubs(:refresh_token).returns("refreshed_secret")
    end

    it "fetches the token from aud prefix" do
      ::PluginStore.set('mozilla-iam', "example.com_token", exp: Time.now.to_i + 1000, access_token: "secret")
      expect(api.send(:access_token)).to eq "secret"
    end

    it "refreshes the token if there's no saved token" do
      expect(api.send(:access_token)).to eq "refreshed_secret"
    end

    it "refreshes the token if the saved token is expired" do
      ::PluginStore.set('mozilla-iam', "example.com_token", exp: Time.now.to_i, access_token: "secret")
      expect(api.send(:access_token)).to eq "refreshed_secret"
    end
  end

  context "#refresh_token" do
    it "stores token with aud prefix" do
      api.expects(:fetch_token).returns("token")
      api.expects(:verify_token).with("token").returns({ "exp" => "exp" })
      token = api.send(:refresh_token)
      saved_token = ::PluginStore.get('mozilla-iam', "example.com_token")
      expect(token).to eq "token"
      expect(saved_token[:access_token]).to eq "token"
      expect(saved_token[:exp]).to eq "exp"
    end
  end

  context "#fetch_token" do
    it "fetches token from token_endpoint" do
      stub_request(:post, "https://example.com/oauth/token").with(
        body: {
          grant_type: "client_credentials",
          client_id: "abc",
          client_secret: "def",
          audience: "example.com"
        }
      ).to_return(status: 200, body: '{"access_token":"fetched_token"}')
      token = api.send(:fetch_token)
      expect(token).to eq "fetched_token"
    end
  end

  context "#verify_token" do
    it "returns verified token" do
      SiteSetting.auth0_domain = "example.com"
      MozillaIAM::JWKS.expects(:public_key).with("jwt").returns("public_key")
      ::JWT.expects(:decode).with("jwt", "public_key", true, {
        algorithm: "RS256",
        iss: "https://example.com/",
        aud: "example.com",
        sub: "abc@clients",
        verify_iss: true,
        verify_iat: true,
        verify_aud: true,
        verify_sub: true,
        verify_iss: true
      }).returns(["verified_token", "header"])
      token = api.send(:verify_token, "jwt")
      expect(token).to eq "verified_token"
    end
  end
end
