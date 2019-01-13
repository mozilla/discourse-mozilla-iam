module MozillaIAM
  Profile.class_eval do
    during_refresh :update_groups

    private

    def update_groups
      in_mapped_groups = false
      GroupMapping.all.each do |mapping|
        if attr(:groups).include?(mapping.iam_group_name)
          in_mapped_groups = true
          add_to_group(mapping.group)
        else
          remove_from_group(mapping.group)
        end
      end
      set(:in_mapped_groups, in_mapped_groups)
    end

    def add_to_group(group)
      unless group.users.exists?(@user.id)
        group.users << @user
      end
    end

    def remove_from_group(group)
      group.users.delete(@user)
    end
  end
end
