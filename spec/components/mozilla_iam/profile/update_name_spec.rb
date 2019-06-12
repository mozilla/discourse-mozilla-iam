require_relative '../../../iam_helper'

describe MozillaIAM::Profile do

  shared_context "shared context" do
    let!(:name_before) { user.name }
  end

  shared_context "with attribute already set" do
    before do
      profile.expects(:attr).with(:full_name).returns(name_before)
    end
  end

  shared_examples "no change" do
    it "does nothing" do
      profile.send(:update_name)
      user.reload
      expect(user.name).to eq name_before
    end
  end

  shared_examples "undefines" do
    it "makes the user's name blank" do
      profile.send(:update_name)
      user.reload
      expect(user.name).to eq ""
    end
  end

  shared_examples "with dinopark_enabled? set to true" do
    context "with a dinopark full_name" do
      before do
        profile.expects(:attr).with(:full_name).returns("John Smith")
      end

      it "updates the user's name" do
        profile.send(:update_name)
        user.reload
        expect(user.name).to eq "John Smith"
      end

    end
  end

  include_examples "dinopark refresh method", :update_name, :full_name
end
