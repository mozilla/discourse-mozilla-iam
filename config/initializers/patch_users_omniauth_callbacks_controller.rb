Users::OmniauthCallbacksController.view_paths = ["plugins/discourse-mozilla-iam/app/views", "app/views"]
Users::OmniauthCallbacksController.class_eval do
  def failure
    render 'failure'
  end
end
