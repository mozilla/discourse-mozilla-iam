require_relative '../iam_helper'

describe UserSerializer do
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
      let(:json) { UserSerializer.new(user, scope: Guardian.new(user), root: false).as_json }
      include_examples "shown"
    end

    context "as an admin" do
      let(:admin) { Fabricate(:admin) }
      let(:json) { UserSerializer.new(user, scope: Guardian.new(admin), root: false).as_json }
      include_examples "not shown"
      include_examples "staged shown"
    end

    context "as a moderator" do
      let(:moderator) { Fabricate(:moderator) }
      let(:json) { UserSerializer.new(user, scope: Guardian.new(moderator), root: false).as_json }
      include_examples "not shown"
      include_examples "staged shown"
    end

    context "as another user" do
      let(:user2) { Fabricate(:user) }
      let(:json) { UserSerializer.new(user, scope: Guardian.new(user2), root: false).as_json }
      include_examples "not shown"
    end

    context "as an anonymous user" do
      let(:json) { UserSerializer.new(user, scope: Guardian.new, root: false).as_json }
      include_examples "not shown"
    end
  end
end
