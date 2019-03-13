Users::OmniauthCallbacksController.view_paths = [File.expand_path("../../app/views", __dir__), "app/views"]
Users::OmniauthCallbacksController.class_eval do
  def failure
    render 'failure'
  end
end
