module MozillaIAM
  class JWKS
    class << self
      def public_key(jwt)
        header = ::JWT::Decode.new(jwt, nil, false, nil).decode_segments.second
        key = jwks['keys'].find { |key| key['kid'] == header['kid'] }
        cert = OpenSSL::X509::Certificate.new(Base64.decode64(key['x5c'][0]))
        cert.public_key
      end

      def jwks
        response = Faraday.get('https://' + SiteSetting.auth0_domain + '/.well-known/jwks.json')
        MultiJson.load(response.body)
      end
    end
  end
end
