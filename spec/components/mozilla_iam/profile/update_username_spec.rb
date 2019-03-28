require_relative '../../../iam_helper'

describe MozillaIAM::Profile do

  shared_context "shared context" do
    let!(:username_before) { user.username }
  end

  shared_context "with attribute already set" do
    before do
      profile.expects(:attr).with(:username).returns(username_before)
      user.expects(:change_username).never
    end
  end

  shared_examples "no change" do
    it "does nothing" do
      profile.send(:update_username)
      user.reload
      expect(user.username).to eq username_before
    end
  end

  shared_examples "undefines" do
    include_examples "no change"
  end

  shared_examples "updates username" do
    it "updates username" do
      profile.send(:update_username)
      user.reload
      expect(user.username).to_not eq username_before
      expect(user.username).to eq username_after
    end
  end

  shared_examples "with dinopark_enabled? set to true" do

    context "with a dinopark username" do
      let(:username_after) { "Johnsmith" }
      before do
        profile.expects(:attr).with(:username).returns(username_after).at_least_once
      end

      include_examples "updates username"

      it "handles taken usernames" do
        Fabricate(:user, username: username_after)
        Fabricate(:user, username: "#{username_after}1")
        profile.send(:update_username)
        user.reload
        expect(user.username).to_not eq username_before
        expect(user.username).to eq "#{username_after}2"
      end

      it "handles usernames that are too long" do
        SiteSetting.max_username_length = 8
        profile.send(:update_username)
        user.reload
        expect(user.username).to_not eq username_before
        expect(user.username).to eq "Johnsmit"
      end

      it "handles taken usernames that are too long" do
        SiteSetting.max_username_length = 8
        Fabricate(:user, username: "johnsmit")
        (1..9).each do |n|
          Fabricate(:user, username: "johnsmi#{n}")
        end
        profile.send(:update_username)
        user.reload
        expect(user.username).to_not eq username_before
        expect(user.username).to eq "Johnsm10"
      end

      it "doesn't allow reserved usernames" do
        SiteSetting.reserved_usernames = username_after.downcase
        profile.send(:update_username)
        user.reload
        expect(user.username).to_not eq username_after
        expect(user.username).to eq username_before
      end

      it "logs errors" do
        user.expects(:change_username).returns(false)
        Rails.logger.expects(:error).with do |e|
          e.start_with? "Mozilla IAM: Error updating username for user #{user.id}"
        end
        profile.send(:update_username)
      end
    end

    context "with dinopark username already set in different case" do
      let(:username_after) { username_before.upcase }
      before do
        profile.expects(:attr).with(:username).returns(username_after)
      end

      include_examples "updates username"
    end
  end

  include_examples "dinopark refresh method", :update_username, :username
end
