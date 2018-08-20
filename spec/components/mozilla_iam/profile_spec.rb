require_relative '../../iam_helper'

describe MozillaIAM::Profile do
  let(:user) { Fabricate(:user) }
  let(:profile) { MozillaIAM::Profile.new(user, "uid") }

  context '.refresh' do
    it "refreshes a user who already has a profile" do
      profile
      MozillaIAM::Profile.expects(:new).with(user, "uid").returns(profile)
      MozillaIAM::Profile.any_instance.expects(:refresh).returns(true)
      result = MozillaIAM::Profile.refresh(user)
      expect(result).to be true
    end

    it 'should return nil if user has no profile' do
      result = MozillaIAM::Profile.refresh(user)
      expect(result).to be_nil
    end
  end

  context '#initialize' do
    it "should save a user's uid" do
      profile
      expect(user.custom_fields['mozilla_iam_uid']).to eq("uid")
    end
  end

  context '#refresh' do
    it "returns #force_refresh if #should_refresh? is true" do
      profile.expects(:should_refresh?).returns(true)
      profile.expects(:last_refresh).never
      profile.expects(:force_refresh).once.returns(true)
      expect(profile.refresh).to be true
    end

    it "returns #last_refresh if #should_refresh? is false" do
      profile.expects(:should_refresh?).returns(false)
      profile.expects(:force_refresh).never
      profile.expects(:last_refresh).once.returns(true)
      expect(profile.refresh).to be true
    end
  end

  context "#force_refresh" do
    it "calls update_groups" do
      profile.expects(:update_groups)
      profile.force_refresh
    end

    it "sets the last refresh to now and returns it" do
      profile.expects(:set_last_refresh).with() { |t| t.between?(Time.now() - 5, Time.now()) }.returns("time now")
      expect(profile.force_refresh).to eq "time now"
    end
  end

  context "#groups" do
    it "merges app_metadata.groups into groups from management api" do
      profile.expects(:mgmt_profile).at_least_once.returns(groups: ['a'], app_metadata: { groups: ['b', 'a', 'c'] })
      expect(profile.groups).to eq ['a', 'b', 'c']
    end

    it "returns app_metadata.groups when groups is nil" do
      profile.expects(:mgmt_profile).at_least_once.returns(app_metadata: { groups: ['a', 'b', 'c'] })
      expect(profile.groups).to eq ['a', 'b', 'c']
    end

    it "returns groups when app_metadata is nil" do
      profile.expects(:mgmt_profile).at_least_once.returns(groups: ['a', 'b', 'c'])
      expect(profile.groups).to eq ['a', 'b', 'c']
    end

    it "returns empty array when groups and app_metadata are nil" do
      profile.expects(:mgmt_profile).at_least_once.returns({})
      expect(profile.groups).to eq []
    end
  end

  context "#mgmt_profile" do
    it "returns a user's profile from the Management API and stores it in an instance variable" do
      MozillaIAM::API::Management.any_instance.expects(:profile).with("uid").returns("profile")
      expect(profile.send(:mgmt_profile)).to eq "profile"
      expect(profile.instance_variable_get(:@mgmt_profile)).to eq "profile"
    end
  end

  context "#last_refresh" do
    it "returns a user's last refreshed time if set and stores it in an instance variable" do
      time_string = Time.now().to_s
      time = Time.parse(time_string)
      profile.expects(:get).returns(time_string)
      expect(profile.send(:last_refresh)).to eq time
      expect(profile.instance_variable_get(:@last_refresh)).to eq time
    end

    it "returns nil if a user's has no last refresh time" do
      profile.expects(:get).returns(nil)
      expect(profile.send(:last_refresh)).to be_nil
    end
  end

  context "#set_last_refresh" do
    it "stores a time and stores it in an instance variable" do
      time = Time.now()
      profile.expects(:set).with(:last_refresh, time).returns(time)
      expect(profile.send(:set_last_refresh, time)).to eq time
      expect(profile.instance_variable_get(:@last_refresh)).to eq time
    end
  end

  context "#should_refresh?" do
    it "returns true if last_refresh is nil" do
      profile.expects(:last_refresh).returns(nil)
      expect(profile.send(:should_refresh?)).to be true
    end

    it "returns true if last_refresh was over 15 minutes ago" do
      profile.expects(:last_refresh).at_least_once.returns(Time.now() - 16.minutes)
      expect(profile.send(:should_refresh?)).to be true
    end

    it "returns false if last_refresh was within 15 minutes ago" do
      profile.expects(:last_refresh).at_least_once.returns(Time.now() - 14.minutes)
      expect(profile.send(:should_refresh?)).to be false
    end
  end

  context '#update_groups' do
    let(:user) { Fabricate(:user) }
    let(:uid) { create_uid(user.username) }
    let(:group) { Fabricate(:group) }

    before do
      MozillaIAM::GroupMapping.new(iam_group_name: 'iam_group',
                                   group: group).save!
    end

    it 'should remove a user from a mapped group' do
      profile.expects(:groups).returns([])
      group.users << user

      expect(group.users.count).to eq 1

      profile.send(:update_groups)

      expect(group.users.count).to eq 0
    end

    it 'should add a user to a mapped group' do
      profile.expects(:groups).returns(['iam_group'])
      expect(group.users.count).to eq 0

      profile.send(:update_groups)

      expect(group.users.count).to eq 1
    end

    it 'should work if groups attribute is undefined' do
      expect(group.users.count).to eq 0

      MozillaIAM::API::Management.any_instance.expects(:profile).returns(groups: nil, app_metadata: { groups: nil })

      profile.send(:update_groups)
      expect(group.users.count).to eq 0
    end

    it 'should work if groups attribute is an empty string' do
      expect(group.users.count).to eq 0

      MozillaIAM::API::Management.any_instance.expects(:profile).returns(groups: '', app_metadata: { groups: '' })

      profile.send(:update_groups)
      expect(group.users.count).to eq 0
    end

    it 'should work if groups attribute is "None"' do
      expect(group.users.count).to eq 0

      MozillaIAM::API::Management.any_instance.expects(:profile).returns(groups: "None", app_metadata: { groups: "None" })

      profile.send(:update_groups)
      expect(group.users.count).to eq 0
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

  context ".get" do
    it "returns a value for the key" do
      described_class.set(user, "key", "value")
      expect(described_class.get(user, "key")).to eq "value"
    end
  end

  context "#get" do
    it "calls .get with the user" do
      described_class.expects(:get).with(user, "key").returns("value")
      expect(profile.send(:get, "key")).to eq "value"
    end
  end

  context ".set" do
    it "saves the value for a key and returns it" do
      value = described_class.set(user, "key", "value")
      expect(value).to eq "value"
      expect(described_class.get(user, "key")).to eq "value"
    end
  end

  context "#set" do
    it "calls .set with the user" do
      profile
      described_class.expects(:set).with(user, "key", "value").returns("value")
      expect(profile.send(:set, "key", "value")).to eq "value"
    end
  end
end
