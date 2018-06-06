module MozillaIAM
  module OmniAuthOAuth2Extensions

    def authorize_params
      params = super
      if request.params.has_key? 'go_back'
        params[:prompt] = 'login'
      end
      params
    end

    def callback_phase
      if request.params.any?
        super
      else
        redirect '/auth/auth0?go_back'
      end
    end

  end
end
