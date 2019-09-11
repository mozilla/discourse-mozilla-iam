Discourse::Application.routes.append do
  get '/admin/plugins/mozilla-iam' => 'admin/plugins#index'
  get '/admin/plugins/mozilla-iam/*all' => 'admin/plugins#index'
  mount MozillaIAM::Engine => '/mozilla_iam'
end

MozillaIAM::Engine.routes.draw do
  namespace :admin, constraints: AdminConstraint.new do
    resources :group_mappings, path: :mappings
  end
  post :notification, to: "notification#notification"
  post :dinopark_link, to: "dinopark_link#link"
  post :dinopark_unlink, to: "dinopark_link#unlink"
  post "/dinopark_link/dont_show", to: "dinopark_link#dont_show"
end
