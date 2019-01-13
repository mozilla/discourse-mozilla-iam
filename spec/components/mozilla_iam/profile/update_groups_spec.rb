require_relative '../../../iam_helper'

describe MozillaIAM::Profile do
  describe described_class.refresh_methods do
    it { should include(:update_groups) }
  end

  let(:user) { Fabricate(:user) }
  let(:profile) { MozillaIAM::Profile.new(user, "uid") }

  context '#update_groups' do
    let(:group) { Fabricate(:group) }

    before do
      MozillaIAM::GroupMapping.new(iam_group_name: 'iam_group',
                                   group: group).save!
    end

    it 'should remove a user from a mapped group' do
      profile.expects(:attr).with(:groups).returns([])
      group.users << user

      expect(group.users.count).to eq 1

      profile.send(:update_groups)

      expect(group.users.count).to eq 0
    end

    it 'should add a user to a mapped group' do
      profile.expects(:attr).with(:groups).returns(['iam_group'])
      expect(group.users.count).to eq 0

      profile.send(:update_groups)

      expect(group.users.count).to eq 1
    end

    context "when a user is in a mapped group" do
      it "sets in_mapped_groups to true" do
        profile.expects(:attr).with(:groups).returns(['iam_group'])
        profile.send(:update_groups)
        expect(profile.send(:get, :in_mapped_groups)).to eq "t"
      end
    end

    context "when a user isn't in any mapped groups" do
      it "sets in_mapped_groups to false" do
        profile.expects(:attr).with(:groups).returns([])
        profile.send(:update_groups)
        expect(profile.send(:get, :in_mapped_groups)).to eq "f"
      end
    end
  end

  context "#add_to_group" do
    it "adds the user to a group" do
      group = Fabricate(:group)
      profile.send(:add_to_group, group)
      expect(group.users.first).to eq user
    end
  end

  context "#remove_from_group" do
    it "removes the user from a group" do
      group = Fabricate(:group, users: [user])
      profile.send(:remove_from_group, group)
      expect(group.users.count).to eq 0
    end

    it "doesn't error out when removing a user from a group they're not in" do
      group = Fabricate(:group)
      profile.send(:remove_from_group, group)
      expect(group.users.count).to eq 0
    end
  end
end
