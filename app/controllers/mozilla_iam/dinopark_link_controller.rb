# frozen_string_literal: true

module MozillaIAM
  class DinoparkLinkController < ApplicationController
    requires_login
    before_action :ensure_logged_in

    def link
      profile = Profile.for(current_user)
      profile.dinopark_enabled = true
      profile.force_refresh
      cookies.delete(:authentication_data)
      render json: { success: true }, status: 200
    end

    def unlink
      profile = Profile.for(current_user)
      profile.force_refresh
      profile.dinopark_enabled = false
      current_user.update(title: nil)
      current_user.user_profile.update(website: nil)
      render json: { success: true }, status: 200
    end

    def dont_show
      Profile.set(current_user, :never_show_dinopark_modal, true)
      cookies.delete(:authentication_data)
      render json: { success: true }, status: 200
    end

  end
end
