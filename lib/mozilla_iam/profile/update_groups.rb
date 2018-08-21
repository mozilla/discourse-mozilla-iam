module MozillaIAM
  Profile.class_eval do
    during_refresh :update_groups

    private

    def update_groups
      GroupMapping.all.each do |mapping|
        if attr(:groups).include?(mapping.iam_group_name)
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
  end
end
