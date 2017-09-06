module MozillaIAM
  class API
    class << self

      def user(uid)
        Rails.logger.info("Auth0 API query for user_id: #{uid}")
        profile = get("users/#{uid}", fields: 'app_metadata')
        { app_metadata: {} }.merge(profile)[:app_metadata]
      end

      private

      def get(path, params = false)
        path = URI.encode(path)
        uri = URI("https://#{SiteSetting.auth0_domain}/api/v2/#{path}")
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
        api_creds = ::PluginStore.get('mozilla-iam', 'api_creds')
        if api_creds.nil? || api_creds[:exp] < Time.now.to_i + 60
          refresh_token
        else
          api_creds[:access_token]
        end
      end

      def refresh_token
        token = fetch_token
        payload = verify_token(token)
        ::PluginStore.set('mozilla-iam', 'api_creds', { access_token: token, exp: payload['exp'] })
        token
      end

      def fetch_token
        response =
          Faraday.post(
            'https://' + SiteSetting.auth0_domain + '/oauth/token',
            {
              grant_type: 'client_credentials',
              client_id: SiteSetting.auth0_client_id,
              client_secret: SiteSetting.auth0_client_secret,
              audience: 'https://' + SiteSetting.auth0_domain + '/api/v2/'
            }
          )
        MultiJson.load(response.body)['access_token']
      end

      def verify_token(token)
        payload, header =
          JWT.decode(
            token,
            aud: 'https://' + SiteSetting.auth0_domain + '/api/v2/',
            sub: SiteSetting.auth0_client_id + '@clients',
            verify_sub: true
          )
        payload
      end
    end
  end
end
