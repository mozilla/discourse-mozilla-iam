module MozillaIAM
  class API
    def initialize(config)
      @client_id = config[:client_id] || SiteSetting.auth0_client_id
      @client_secret = config[:client_secret] || SiteSetting.auth0_client_secret
      @token_endpoint = config[:token_endpoint] || "https://#{SiteSetting.auth0_domain}/oauth/token"
      @url = config[:url]
      raise ArgumentError, "no url in config" unless @url
      @aud = config[:aud]
      raise ArgumentError, "no aud in config" unless @aud
    end

    private

    def get(path, params = false)
      path = URI.encode(path)
      uri = URI("#{@url}/#{path}")
      uri.query = URI.encode_www_form(params) if params

      req = Net::HTTP::Get.new(uri)
      req['Authorization'] = "Bearer #{access_token}"

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      if res.code == '200'
        MultiJson.load(res.body, symbolize_keys: true)
      else
        {}
      end
    end

    def access_token
      api_token = ::PluginStore.get('mozilla-iam', "#{@aud}_token")
      if api_token.nil? || api_token[:exp] < Time.now.to_i + 60
        refresh_token
      else
        api_token[:access_token]
      end
    end

    def refresh_token
      token = fetch_token
      payload = verify_token(token)
      ::PluginStore.set('mozilla-iam', "#{@aud}_token", { access_token: token, exp: payload['exp'] })
      token
    end

    def fetch_token
      response =
        Faraday.post(
          @token_endpoint,
          {
            grant_type: 'client_credentials',
            client_id: @client_id,
            client_secret: @client_secret,
            audience: @aud
          }
        )
      MultiJson.load(response.body)['access_token']
    end

    def verify_token(token)
      payload, header =
        JWT.decode(
          token,
          aud: @aud,
          sub: @client_id + '@clients',
          verify_sub: true
        )
      payload
    end
  end
end
