require_relative '../../iam_helper'

describe MozillaIAM::Profile do
  let(:user) { Fabricate(:user_with_secondary_email) }
  let(:profile) { MozillaIAM::Profile.new(user, "uid") }

  describe ".during_refresh" do
    it "adds methods to .refresh_methods" do
      described_class.during_refresh :foo
      expect(described_class.refresh_methods).to include :foo

      described_class.during_refresh :bar
      expect(described_class.refresh_methods).to include :bar

      described_class.refresh_methods.delete(:foo)
      described_class.refresh_methods.delete(:bar)
      expect(described_class.refresh_methods).not_to include :foo
      expect(described_class.refresh_methods).not_to include :bar
    end
  end

  describe ".register_as_array" do
    it "adds key to .array_keys" do
      described_class.register_as_array :foo
      expect(described_class.array_keys).to include :foo

      described_class.register_as_array :bar
      expect(described_class.array_keys).to include :bar

      described_class.array_keys.delete(:foo)
      described_class.array_keys.delete(:bar)
      expect(described_class.array_keys).not_to include :foo
      expect(described_class.array_keys).not_to include :bar
    end
  end

  context '.refresh' do
    it "refreshes a user who already has a profile" do
      profile
      MozillaIAM::Profile.expects(:new).with(user, "uid").returns(profile)
      MozillaIAM::Profile.any_instance.expects(:refresh).returns(true)
      result = MozillaIAM::Profile.refresh(user)
      expect(result).to be true
    end

    it 'returns nil if user has no profile' do
      result = MozillaIAM::Profile.refresh(user)
      expect(result).to be_nil
    end
  end

  describe ".for" do
    it "returns a user who has a profile" do
      profile
      MozillaIAM::Profile.expects(:new).with(user, "uid").returns(profile)
      result = described_class.for(user)
      expect(result).to eq profile
    end

    it 'returns nil if user has no profile' do
      result = described_class.for(user)
      expect(result).to be_nil
    end
  end

  describe ".find_by_uid" do
    it "returns a user who has the uid" do
      profile
      MozillaIAM::Profile.expects(:new).with(user, "uid").returns(profile)
      result = described_class.find_by_uid("uid")
      expect(result).to eq profile
    end

    it "returns nil if there's no user with that uid" do
      result = described_class.find_by_uid("uid")
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
    it "runs methods in refresh_methods" do
      described_class.expects(:refresh_methods).returns([:one, :two])
      profile.expects(:one).once
      profile.expects(:two).once
      profile.force_refresh
    end

    it "clears Profile cache" do
      class MockAPI
        def self.profile(uid); Profile.new(SecureRandom.base64); end
        class Profile
          attr_accessor :rand
          def initialize(rand); @rand = rand; end
        end
      end
      MozillaIAM::API.stubs(:profile_apis).returns([MockAPI])
      described_class.stubs(:refresh_methods).returns([])

      profile.force_refresh
      orig_rand = profile.attr(:rand)

      profile.force_refresh
      expect(profile.attr(:rand)).not_to eq orig_rand

      remove_consts([:MockAPI])
    end

    it "sets the last refresh to now and returns it" do
      described_class.expects(:refresh_methods).returns([])
      profile.expects(:set_last_refresh).with() { |t| t.between?(Time.now() - 5, Time.now()) }.returns("time now")
      expect(profile.force_refresh).to eq "time now"
    end
  end

  describe "#attr" do
    before do
      class Foo
        def self.profile(uid); Profile.new(SecureRandom.base64); end
        class Profile
          attr_accessor :rand
          def initialize(rand); @rand = rand; end
          def foo; :foo; end
          def foobar; :foo; end
          def array; [1, 2, 3]; end
        end
      end
      class Bar
        def self.profile(uid); Profile.new; end
        class Profile
          def bar; :bar; end
          def foobar; :bar; end
          def array; [3, 4, 5]; end
        end
      end
      MozillaIAM::API.stubs(:profile_apis).returns([Foo, Bar])
    end

    context "when Foo defines attribute" do
      it "returns Foo's attribute" do
        expect(profile.attr(:foo)).to eq :foo
      end
    end

    context "when Bar defines attribute" do
      it "returns Bar's attribute" do
        expect(profile.attr(:bar)).to eq :bar
      end
    end

    context "when both Foo and Bar define attribute" do
      it "returns the attribute from the first element of API.profile_apis which defines it" do
        expect(profile.attr(:foobar)).to eq :foo

        MozillaIAM::API.stubs(:profile_apis).returns([Bar, Foo])
        expect(profile.attr(:foobar)).to eq :bar
      end

      it "takes the union of the attribute if it's an array" do
        expect(profile.attr(:array)).to contain_exactly(1, 2, 3, 4, 5)
      end
    end

    it "caches Profile instances" do
      orig_rand = profile.attr(:rand)
      expect(profile.attr(:rand)).to eq orig_rand
    end

    after do
      remove_consts([:Foo, :Bar])
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
