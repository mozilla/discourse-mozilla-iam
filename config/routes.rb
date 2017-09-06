Discourse::Application.routes.append do
  get '/admin/plugins/mozilla-iam' => 'admin/plugins#index'
  get '/admin/plugins/mozilla-iam/*all' => 'admin/plugins#index'
  mount MozillaIAM::Engine => '/mozilla_iam'
end

MozillaIAM::Engine.routes.draw do
  namespace :admin, constraints: AdminConstraint.new do
    resources :group_mappings, path: :mappings
  end
end
