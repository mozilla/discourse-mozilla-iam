module MozillaIAM
  class GroupMappingSerializer < ApplicationSerializer
    attributes :id,
               :group_name,
               :iam_group_name

    def group_name
      object.group.name
    end
  end
end
