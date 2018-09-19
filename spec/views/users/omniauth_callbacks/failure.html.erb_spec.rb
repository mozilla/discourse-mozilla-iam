require_relative "../../../iam_helper"

describe "users/omniauth_callbacks/failure.html.erb" do

  it "renders the failure page with custom error" do
    flash[:error] = "custom error 1234"
    render
    expect(rendered.match("custom error 1234")).not_to eq(nil)
  end

  it "renders the failure page with default error" do
    render
    expect(I18n.t("login.omniauth_error_unknown", default: nil)).not_to eq(nil)
    expect(rendered.match(I18n.t("login.omniauth_error_unknown"))).not_to eq(nil)
  end

end
