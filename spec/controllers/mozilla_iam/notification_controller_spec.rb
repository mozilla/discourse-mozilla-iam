require_relative '../../iam_helper'

describe MozillaIAM::NotificationController, type: :request do
  describe "#notification" do

    let(:user) { Fabricate(:user) }

    before do
      stub_jwks_request
    end

    shared_context "no JWT" do
      let(:headers) do
        { "Content-Type": "application/json" }
      end
    end

    shared_context "invalid JWT" do
      let(:jwt) do
        create_jwt({
          iss: 'https://auth.mozilla.auth0.com/',
          aud: 'nope',
          exp: Time.now.to_i + 7.days,
          iat: Time.now.to_i,
        }, {
          kid: 'the_best_key'
        })
      end
      let(:headers) do
        {
          "Content-Type": "application/json",
          "Authorization": "Bearer #{jwt}"
        }
      end
    end

    shared_context "valid JWT" do
      let(:jwt) do
        create_jwt({
          iss: 'https://auth.mozilla.auth0.com/',
          aud: 'hook.prod.sso.mozilla.com',
          exp: Time.now.to_i + 7.days,
          iat: Time.now.to_i,
        }, {
          kid: 'the_best_key'
        })
      end
      let(:headers) do
        {
          "Content-Type": "application/json",
          "Authorization": "Bearer #{jwt}"
        }
      end
    end

    shared_examples "does nothing" do
      it "does nothing" do
        MozillaIAM::Profile.any_instance.expects(:force_refresh).never
        post "/mozilla_iam/notification", params: notification.to_json, headers: headers
        expect(response.status).to eq 200
      end
    end

    shared_examples "error" do
      context "with no JWT" do
        include_context "no JWT"

        it "errors out" do
          post "/mozilla_iam/notification", params: notification.to_json, headers: headers
          expect(response.status).to eq 400
          expect(response.body).to eq "Invalid JWT"
        end
      end

      context "with an invalid JWT" do
        include_context "invalid JWT"

        it "errors out" do
          post "/mozilla_iam/notification", params: notification.to_json, headers: headers
          expect(response.status).to eq 400
          expect(response.body).to eq "Invalid JWT"
        end
      end
    end

    shared_examples "success" do
      context "with a valid JWT" do
        include_context "valid JWT"

        context "with a user_id which doesn't exist" do
          include_examples "does nothing"
        end

        context "with a user_id which exists" do
          before do
            user.custom_fields["mozilla_iam_uid"] = notification[:id]
            user.save_custom_fields
          end

          it "refreshes user" do
            MozillaIAM::Profile.any_instance.expects(:force_refresh)
            post "/mozilla_iam/notification", params: notification.to_json, headers: headers
            expect(response.status).to eq 200
          end
        end

      end
    end

    context "with an update notification" do
      let(:notification) do
        {
          operation: "update",
          id: "ad|Mozilla-LDAP|dinomcvouch",
          time: Time.now
        }
      end

      include_examples "error"
      include_examples "success"

    end

    context "with a delete notification" do
      let(:notification) do
        {
          operation: "delete",
          id: "ad|Mozilla-LDAP|dinomcvouch",
          time: Time.now
        }
      end

      include_examples "error"
      include_examples "success"

    end

    context "with a create notification" do
      let(:notification) do
        {
          operation: "create",
          id: "ad|Mozilla-LDAP|dinomcvouch",
          time: Time.now
        }
      end

      context "with no JWT" do
        include_context "no JWT"
        include_examples "does nothing"
      end

      context "with invalid JWT" do
        include_context "invalid JWT"
        include_examples "does nothing"
      end

      context "with valid JWT" do
        include_context "valid JWT"
        include_examples "does nothing"
      end

    end

  end
end
