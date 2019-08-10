# frozen_string_literal: true

module MozillaIAM
  class DinoparkLinkController < ApplicationController
    requires_login
    before_action :ensure_logged_in

    def link
      profile = Profile.for(current_user)
      profile.dinopark_enabled = true
      profile.force_refresh
      render json: { success: true }, status: 200
    end

  end
end
