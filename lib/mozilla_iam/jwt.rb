module MozillaIAM
  class JWT
    class << self
      def decode(token, opts)
        public_key = JWKS.public_key(token)
        ::JWT.decode(
          token,
          public_key,
          true,
          {
            algorithm: 'RS256',
            iss: 'https://' + SiteSetting.auth0_domain + '/',
            verify_iss: true,
            verify_iat: true,
            verify_aud: true
          }.merge(opts)
        )
      end
    end
  end
end
