module MozillaIAM
  module UsersControllerExtensions

    def create
      params.permit(:dinopark_enabled)
      if dinopark_enabled = params[:dinopark_enabled]
        session[:authentication][:dinopark_enabled] = dinopark_enabled
        params[:username] = UserNameSuggester.find_available_username_based_on(params[:username])
      end
      super
    end

  end
end
