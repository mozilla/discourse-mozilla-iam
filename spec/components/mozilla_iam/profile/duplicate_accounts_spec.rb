require_relative '../../../iam_helper'

describe MozillaIAM::Profile do
  describe "#duplicate_accounts" do
    let(:user) { Fabricate(:user_with_secondary_email) }
    let(:profile) { MozillaIAM::Profile.new(user, "uid") }

    context "when no emails are taken" do
      it "returns empty array" do
        expect(profile.duplicate_accounts).to eq []
      end
    end

    context "when email is taken" do
      let!(:duplicate_user) { Fabricate(:user_with_secondary_email, email: "taken@email.com") }
      before { profile.send :set, "taken_emails", ["taken@email.com"] }

      it "returns user_id of duplicate account" do
        expect(profile.duplicate_accounts).to contain_exactly duplicate_user
      end
    end

    context "when emails are taken and one user has multiple" do
      let!(:duplicate_user1) { Fabricate(:user_with_secondary_email, email: "taken1@email.com") }
      let!(:duplicate_user2) { Fabricate(:user_with_secondary_email) }
      before do
        profile.send :set, "taken_emails", [
          "taken1@email.com",
          "taken2@email.com",
          "taken3@email.com"
        ]
        Fabricate(:secondary_email, user: duplicate_user2, email: "taken2@email.com")
        Fabricate(:secondary_email, user: duplicate_user1, email: "taken3@email.com")
      end

      it "returns unique user_ids of duplicate accounts" do
        expect(profile.duplicate_accounts).to contain_exactly duplicate_user1, duplicate_user2
      end
    end

    context "when email registered as taken isn't" do
      let!(:duplicate_user) { Fabricate(:user_with_secondary_email, email: "taken@email.com") }
      before do
        profile.send :set, "taken_emails", [
          "taken@email.com",
          "no_longer_taken@email.com"
        ]
      end

      it "adds not taken email to user" do
        expect(profile.duplicate_accounts).to contain_exactly duplicate_user
        expect(user.secondary_emails).to include "no_longer_taken@email.com"
      end

      context "and user already has taken email" do
        before { Fabricate(:secondary_email, user: user, email: "no_longer_taken@email.com") }
        it "doesn't include user's id" do
          expect(user.secondary_emails).to include "no_longer_taken@email.com"
          expect(profile.duplicate_accounts).to contain_exactly duplicate_user
          expect(user.secondary_emails).to include "no_longer_taken@email.com"
        end
      end
    end
  end
end
