require_relative '../../iam_helper'

describe MozillaIAM::Authenticator do

  context "#enabled?" do
    it "returns true" do
      expect(described_class.new('auth0', trusted: true).enabled?).to be true
    end
  end

  context '#after_authenticate' do
    it 'can authenticate a new user' do
      user = {
        name: 'John Doe',
        email: 'jdoe@mozilla.com',
        username: 'jdoe'
      }
      result = authenticate_user(user)

      expect(result.user).to             eq(nil)
      expect(result.email).to            eq(user[:email])
      expect(result.email_valid).to      eq(true)
      expect(result.name).to             eq(user[:name])
      expect(result.extra_data[:uid]).to eq("ad|Mozilla-LDAP|#{user[:username]}")
    end

    it 'can authenticate and create a profile for an existing user' do
      user = Fabricate(:user_with_secondary_email)
      result = authenticate_user(user)

      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(result.user.id).to          eq(user.id)
      expect(result.email).to            eq(user.email)
      expect(result.email_valid).to      eq(true)
      expect(result.name).to             eq(user.name)
      expect(result.extra_data[:uid]).to eq(create_uid(user.username))
      expect(uid).to                     eq(create_uid(user.username))
      expect(last_refresh).to            be_within(5.seconds).of Time.now
    end

    it 'can refresh an existing profile for an existing user' do
      user = Fabricate(:user_with_secondary_email)
      user.custom_fields['mozilla_iam_uid'] = create_uid(user.username)
      user.custom_fields['mozilla_iam_last_refresh'] = Time.now - 14.minutes
      user.save_custom_fields

      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(uid).to                     eq(create_uid(user.username))
      expect(last_refresh).to            be_within(5.seconds).of Time.now - 14.minutes

      result = authenticate_user(user)

      user.clear_custom_fields
      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(result.user.id).to          eq(user.id)
      expect(result.email).to            eq(user.email)
      expect(result.email_valid).to      eq(true)
      expect(result.name).to             eq(user.name)
      expect(result.extra_data[:uid]).to eq(create_uid(user.username))
      expect(uid).to                     eq(create_uid(user.username))
      expect(last_refresh).to            be_within(5.seconds).of Time.now
    end

    it 'can refresh an existing profile for an existing user with a new uid' do
      user = Fabricate(:user_with_secondary_email)
      old_uid = "the_best_uid"
      new_uid = create_uid(user.username)
      user.custom_fields['mozilla_iam_uid'] = old_uid
      user.custom_fields['mozilla_iam_last_refresh'] = Time.now - 14.minutes
      user.save_custom_fields

      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(uid).to                     eq(old_uid)
      expect(last_refresh).to            be_within(5.seconds).of Time.now - 14.minutes

      result = authenticate_user(user)

      user.clear_custom_fields
      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(result.user.id).to          eq(user.id)
      expect(result.email).to            eq(user.email)
      expect(result.email_valid).to      eq(true)
      expect(result.name).to             eq(user.name)
      expect(result.extra_data[:uid]).to eq(new_uid)
      expect(uid).to                     eq(new_uid)
      expect(last_refresh).to            be_within(5.seconds).of Time.now
    end

    it 'will not log in with an invalid id_token' do
      result = authenticate_with_id_token('really_invalid')

      expect(result.failed).to eq(true)
    end

    it 'will not log in with an expired id_token' do
      user = Fabricate(:user_with_secondary_email)
      id_token = create_id_token(user, { exp: Time.now.to_i, iat: (Time.now - 7.days).to_i })
      result = authenticate_with_id_token(id_token)

      expect(result.failed).to eq(true)
      expect(result.failed_reason).to eq I18n.t("login.omniauth_error_unknown", default: nil)
    end

    it 'will verify email in sign up form with an id_token with an unverified email' do
      user = Fabricate(:user_with_secondary_email)
      id_token = create_id_token(user, { email_verified: false })
      result = authenticate_with_id_token(id_token)

      expect(result.user).to eq(nil)
    end

    it "won't log in a user if they log in with their secondary email" do
      user = Fabricate(:user_with_secondary_email)
      id_token = create_id_token(user, { email: user.secondary_emails.first })
      result = authenticate_with_id_token(id_token)

      expect(result.failed).to eq true
      expect(result.failed_reason).to_not eq I18n.t("login.omniauth_error_unknown")
      expect(result.failed_reason).to eq "Oops, you logged in with #{user.secondary_emails.first},"\
        " which is one of your secondary email addresses. Please log in with #{user.email} instead."
    end

    context "when the AAL" do
      let(:user) { Fabricate(:user_with_secondary_email) }
      let(:id_token) { create_id_token(user, { "https://sso.mozilla.com/claim/AAL" => "LOW" }) }
      before do
        MozillaIAM::Profile.expects(:refresh_methods).returns([:update_groups])
        MozillaIAM::GroupMapping.create(iam_group_name: 'iam_group', group: Fabricate(:group))
      end

      context "is high enough" do
        it "authenticates user" do
          MozillaIAM::Profile.any_instance.expects(:attr).with(:groups).returns([])
          result = authenticate_with_id_token(id_token)

          expect(result.user.id).to eq user.id
        end
      end

      context "is too low" do
        it "doesn't authenticate user" do
          MozillaIAM::Profile.any_instance.expects(:attr).with(:groups).returns(["iam_group"])
          result = authenticate_with_id_token(id_token)

          expect(result.failed).to eq true
          expect(result.failed_reason).to_not eq I18n.t("login.omniauth_error_unknown")
        end
      end
    end

    shared_examples "dinopark_authorized_groups" do
      context "when dinopark_authorized_groups" do
        let(:result) { authenticate_with_id_token(id_token) }
        before do
          MozillaIAM::Profile.stubs(:refresh_methods).returns([])
          SiteSetting.dinopark_authorized_groups = "foo|bar"
        end

        context "intersects with a profile's groups" do
          let(:id_token) { create_id_token(user, { "https://sso.mozilla.com/claim/groups": ["everyone", "foo"] }) }
          it "sets show_dinopark_prompt in extra_data to true" do
            expect(result.failed).to eq false
            expect(result.extra_data[:show_dinopark_prompt]).to eq true
          end
        end

        context "doesn't intersect with a profile's groups" do
          let(:id_token) { create_id_token(user, { "https://sso.mozilla.com/claim/groups": ["everyone"] }) }
          it "sets show_dinopark_prompt in extra_data to false" do
            expect(result.failed).to eq false
            expect(result.extra_data[:show_dinopark_prompt]).to eq false
          end
        end
      end
    end

    describe "show_dinopark_prompt in extra_data" do
      context "when user exists" do
        fab!(:user) { Fabricate(:user) }
        let(:profile) { MozillaIAM::Profile.new(user, create_uid(user.username)) }
        before { SiteSetting.dinopark_authorized_groups = "everyone" }

        context "and their dinopark_enabled flag is true" do
          let(:result) { authenticate_user(user) }
          before { profile.dinopark_enabled = true }

          it "sets show_dinopark_prompt in extra_data to false" do
            expect(result.failed).to eq false
            expect(result.extra_data[:show_dinopark_prompt]).to eq false
          end
        end

        context "and their dinopark_enabled flag is false" do
          before { profile.dinopark_enabled = false }

          context "and their never_show_dinopark_modal flag is true" do
            let(:result) { authenticate_user(user) }
            before { profile.send(:set, :never_show_dinopark_modal, true) }

            it "sets show_dinopark_prompt in extra_data to false" do
              expect(result.failed).to eq false
              expect(result.extra_data[:show_dinopark_prompt]).to eq false
            end
          end

          context "and their never_show_dinopark_modal flag is nil" do
            before { profile.send(:set, :never_show_dinopark_modal, nil) }

            include_examples "dinopark_authorized_groups"
          end
        end
      end

      context "when a user doesn't exist yet" do
        let(:user) {{
          name: 'John Doe',
          email: 'jdoe@mozilla.com',
          username: 'jdoe'
        }}

        include_examples "dinopark_authorized_groups"
      end
    end

  end

  context '#after_create_account' do
    let(:user) { Fabricate(:user_with_secondary_email) }
    let(:authenticator) { MozillaIAM::Authenticator.new('auth0', trusted: true) }
    before do
      MozillaIAM::Profile.stubs(:refresh_methods).returns([])
    end

    it 'can create profile for new user' do
      auth = { extra_data: { uid: create_uid(user.username) }}
      result = authenticator.after_create_account(user, auth)

      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])
      dinopark_enabled = user.custom_fields['mozilla_iam_dinopark_enabled']

      expect(result).to       be_within(5.seconds).of Time.now
      expect(last_refresh).to be_within(5.seconds).of Time.now
      expect(uid).to          eq(create_uid(user.username))
      expect(dinopark_enabled).to be_nil
    end

    context "with dinopark_enabled" do
      it 'can create profile for new user' do
        auth = { dinopark_enabled: true, extra_data: { uid: create_uid(user.username) }}
        result = authenticator.after_create_account(user, auth)

        uid = user.custom_fields['mozilla_iam_uid']
        last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])
        dinopark_enabled = user.custom_fields['mozilla_iam_dinopark_enabled']

        expect(result).to       be_within(5.seconds).of Time.now
        expect(last_refresh).to be_within(5.seconds).of Time.now
        expect(uid).to          eq(create_uid(user.username))
        expect(dinopark_enabled).to eq(true)
      end
    end
  end
end
