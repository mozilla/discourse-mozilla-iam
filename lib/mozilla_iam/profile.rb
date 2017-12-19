module MozillaIAM
  class Profile
    def self.refresh(user)
      uid = get(user, :uid)
      return if uid.blank?
      Profile.new(user, uid).refresh
    end

    def initialize(user, uid)
      @user = user
      @uid = set(:uid, uid)
    end

    def refresh
      return last_refresh unless should_refresh?
      force_refresh
    end

    def force_refresh
      DistributedMutex.synchronize("mozilla_iam_refresh_#{@user.id}") do
        update_groups
        set_last_refresh(Time.now)
      end
    end

    private

    def profile
      @profile ||= ManagementAPI.new.profile(@uid)
    end

    def last_refresh
      @last_refresh ||=
        if time = get(:last_refresh)
          Time.parse(time)
        end
    end

    def set_last_refresh(time)
      @last_refresh = set(:last_refresh, time)
    end

    def should_refresh?
      return true unless last_refresh
      Time.now > last_refresh + 900
    end

    def update_groups
      GroupMapping.all.each do |mapping|
        if mapping.authoritative
          in_group =
            profile[:authoritativeGroups]&.any? do |authoritative_group|
              authoritative_group[:name] == mapping.iam_group_name
            end
        else
          in_group = profile[:groups]&.include?(mapping.iam_group_name)
        end

        if in_group
          add_to_group(mapping.group)
        else
          remove_from_group(mapping.group)
        end
      end
    end

    def add_to_group(group)
      unless group.users.exists?(@user.id)
        group.users << @user
      end
    end

    def remove_from_group(group)
      group.users.delete(@user)
    end

    def self.get(user, key)
      user.custom_fields["mozilla_iam_#{key}"]
    end

    def get(key)
      self.class.get(@user, key)
    end

    def self.set(user, key, value)
      user.custom_fields["mozilla_iam_#{key}"] = value
      user.save_custom_fields
      value
    end

    def set(key, value)
      self.class.set(@user, key, value)
    end
  end
end
