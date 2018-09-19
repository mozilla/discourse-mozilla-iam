module MozillaIAM
  module OmniAuthOAuth2Extensions

    def authorize_params
      params = super
      params[:prompt] = request.params["prompt"] if request.params.has_key? "prompt"
      params[:action] = request.params["action"] if request.params.has_key? "action"
      params
    end

    def callback_phase
      if request.params.any?
        super
      else
        redirect '/auth/auth0?prompt=login'
      end
    end

  end
end
