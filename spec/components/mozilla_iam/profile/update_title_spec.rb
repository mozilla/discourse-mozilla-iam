require_relative '../../../iam_helper'

describe MozillaIAM::Profile do
  describe described_class.refresh_methods do
    it { should include(:update_title) }
  end

  describe "#update_title" do
    let(:user) { Fabricate(:user) }
    let(:profile) { MozillaIAM::Profile.new(user, "uid") }

    shared_examples "no change" do
      it "does nothing" do
        profile.send(:update_title)
        user.reload
        expect(user.title).to eq title_before
      end
    end

    context "with dinopark_enabled? set to false" do
      let!(:title_before) { user.title }
      before do
        profile.dinopark_enabled = false
        profile.expects(:attr).with(:fun_title).never
        profile.expects(:attr).with(:pronouns).never
      end

      include_examples "no change"
    end

    context "with dinopark_enabled? set to true" do
      before do
        profile.dinopark_enabled = true
      end

      context "with empty dinopark fun_title and pronouns" do
        before do
          profile.expects(:attr).with(:fun_title).returns(" ")
          profile.expects(:attr).with(:pronouns).returns(" ")
        end

        it "makes the user's title blank" do
          profile.send(:update_title)
          user.reload
          expect(user.title).to eq ""
        end
      end

      context "with empty dinopark fun_title and value for pronouns" do
        before do
          profile.expects(:attr).with(:fun_title).returns(" ")
          profile.expects(:attr).with(:pronouns).returns("she/her")
        end

        it "makes the user's title blank" do
          profile.send(:update_title)
          user.reload
          expect(user.title).to eq "(she/her)"
        end
      end

      context "with empty dinopark pronouns and value for fun_title" do
        before do
          profile.expects(:attr).with(:fun_title).returns("The World's Best Developer")
          profile.expects(:attr).with(:pronouns).returns(" ")
        end

        it "makes the user's title blank" do
          profile.send(:update_title)
          user.reload
          expect(user.title).to eq "The World's Best Developer"
        end
      end

      context "with values for dinopark pronouns and fun_title" do
        before do
          profile.expects(:attr).with(:fun_title).returns("The World's Best Developer")
          profile.expects(:attr).with(:pronouns).returns("she/her")
        end

        it "makes the user's title blank" do
          profile.send(:update_title)
          user.reload
          expect(user.title).to eq "(she/her) The World's Best Developer"
        end
      end

      context "with dinopark pronouns and fun_title already set" do
        let!(:title_before) { "(she/her) The World's Best Developer" }
        before do
          profile.expects(:attr).with(:fun_title).returns("The World's Best Developer")
          profile.expects(:attr).with(:pronouns).returns("she/her")
          user.update(title: "(she/her) The World's Best Developer")
          user.reload
          user.expects(:update).never
        end

        include_examples "no change"
      end
    end
  end
end
