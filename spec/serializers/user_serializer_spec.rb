require_relative '../iam_helper'

describe UserSerializer do

  shared_context "as the user" do
    let(:json) { UserSerializer.new(user, scope: Guardian.new(user), root: false).as_json }
  end

  shared_context "as an admin" do
    let(:admin) { Fabricate(:admin) }
    let(:json) { UserSerializer.new(user, scope: Guardian.new(admin), root: false).as_json }
  end

  shared_context "as a moderator" do
    let(:moderator) { Fabricate(:moderator) }
    let(:json) { UserSerializer.new(user, scope: Guardian.new(moderator), root: false).as_json }
  end

  shared_context "as another user" do
    let(:user2) { Fabricate(:user) }
    let(:json) { UserSerializer.new(user, scope: Guardian.new(user2), root: false).as_json }
  end

  shared_context "as an anonymous user" do
    let(:json) { UserSerializer.new(user, scope: Guardian.new, root: false).as_json }
  end

  context "with secondary emails" do
    let(:user) { Fabricate(:user_single_email) }

    before do
      ["first", "second"].each do |name|
        Fabricate(:secondary_email, user: user, email: "#{name}@email.com")
      end
    end

    shared_examples "shown" do
      it "contains the user's secondary emails" do
        expect(json[:secondary_emails]).to contain_exactly(
          "first@email.com",
          "second@email.com"
        )
      end
    end

    shared_examples "not shown" do
      it "doesn't contain the user's secondary emails" do
        secondary_emails = json[:secondary_emails]
        expect(secondary_emails).to be_nil
      end
    end

    shared_examples "staged shown" do
      context "with a staged user" do
        before do
          user.staged = true
        end

        include_examples "shown"
      end
    end

    context "as the user" do
      include_context "as the user"
      include_examples "shown"
    end

    context "as an admin" do
      include_context "as an admin"
      include_examples "not shown"
      include_examples "staged shown"
    end

    context "as a moderator" do
      include_context "as a moderator"
      include_examples "not shown"
      include_examples "staged shown"
    end

    context "as another user" do
      include_context "as another user"
      include_examples "not shown"
    end

    context "as an anonymous user" do
      include_context "as an anonymous user"
      include_examples "not shown"
    end
  end

  context "with duplicate accounts" do
    let(:user) { Fabricate(:user) }
    let(:duplicate_user) { Fabricate(:user) }

    before do
      profile = MozillaIAM::Profile.new(user, "uid")
      profile.stubs(:duplicate_accounts).returns([ duplicate_user ])
      MozillaIAM::Profile.stubs(:for).returns(profile)
    end

    shared_examples "shown" do
      it "contains the user's duplicate_accounts" do
        duplicate_accounts = json[:duplicate_accounts]
        expect(duplicate_accounts.length).to eq 1
        account = duplicate_accounts.first
        expect(account.id).to eq duplicate_user.id
        expect(account.username).to eq duplicate_user.username
        expect(account.email).to eq duplicate_user.email
        expect(account.secondary_emails).to eq duplicate_user.secondary_emails
      end
    end

    shared_examples "not shown" do
      it "doesn't contain the user's duplicate_accounts" do
        duplicate_accounts = json[:duplicate_accounts]
        expect(duplicate_accounts).to be_nil
      end
    end

    context "as the user" do
      include_context "as the user"
      include_examples "shown"
    end

    context "as an admin" do
      include_context "as an admin"
      include_examples "shown"
    end

    context "as a moderator" do
      include_context "as a moderator"
      include_examples "not shown"
    end

    context "as another user" do
      include_context "as another user"
      include_examples "not shown"
    end

    context "as an anonymous user" do
      include_context "as an anonymous user"
      include_examples "not shown"
    end
  end
end
