require_relative '../iam_helper'

describe MozillaIAM::SessionData do
  it "is destroyed when associated auth token is destroyed" do

  end

  describe ".find_or_create" do
    let!(:last_refresh) { Time.now.round }
    let(:aal) { "MEDIUM" }
    let(:cookies) { { described_class::TOKEN_COOKIE => "12345" } }
    let(:user_auth_token) { UserAuthToken.generate!(user_id: Fabricate(:user).id) }
    before { UserAuthToken.expects(:lookup).with("12345").returns(user_auth_token) }

    context "with session[:mozilla_iam]" do
      it "should create SessionData record and remove session[:mozilla_iam]" do
        session = {
          mozilla_iam: {
            last_refresh: last_refresh,
            aal: aal
          }
        }

        session_data = described_class.find_or_create(session, cookies)

        expect(user_auth_token.mozilla_iam_session_data).to eq session_data
        expect(session_data.last_refresh).to eq last_refresh
        expect(session_data.aal).to eq aal
        expect(session[:mozilla_iam]).to be_nil
      end
    end

    context "without session[:mozilla_iam]" do
      it "should find SessionData record" do
        described_class.create!(
          user_auth_token_id: user_auth_token.id,
          last_refresh: last_refresh,
          aal: aal
        )

        session_data = described_class.find_or_create({}, cookies)

        expect(user_auth_token.mozilla_iam_session_data).to eq session_data
        expect(session_data.last_refresh).to eq last_refresh
        expect(session_data.aal).to eq aal
      end
    end
  end
end
