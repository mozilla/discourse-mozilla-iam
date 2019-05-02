module MozillaIAM
  module UsersControllerExtensions

    def create
      params.permit(:dinopark_enabled)
      if dinopark_enabled = (params[:dinopark_enabled] == "true")
        session[:authentication] = {} unless session[:authentication]
        session[:authentication][:dinopark_enabled] = dinopark_enabled
        params[:username] = UserNameSuggester.find_available_username_based_on(params[:username])
      end
      super
    end

    def user_params
      result = super
      begin
        if Profile.for(fetch_user_from_params)&.dinopark_enabled?
          [
            :name,
            :title,
            :bio_raw,
            :location,
            :website
          ].each { |x| result.delete(x) }
        end
      rescue Discourse::NotFound
      end
      result
    end

    def username
      if Profile.for(fetch_user_from_params)&.dinopark_enabled?
        render_json_error(I18n.t("dinopark.update_username"))
      else
        super
      end
    end

    def pick_avatar
      if Profile.for(fetch_user_from_params)&.dinopark_enabled?
        render_json_error(I18n.t("dinopark.update_avatar"))
      else
        super
      end
    end

  end
end
