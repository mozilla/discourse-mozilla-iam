require_relative "../iam_helper"

describe "Authentication error" do

  it "loads mozilla failure page" do
    get "/auth/failure"
    expect(response.body).to include 'id="mozilla-iam-auth-error-page"'
  end

  it "says 'please try again' in failure page" do
    get "/auth/failure"
    expect(response.body).to include 'please try again'
  end

end
