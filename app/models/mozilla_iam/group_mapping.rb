module MozillaIAM
  class GroupMapping < ActiveRecord::Base
    belongs_to :group
  end
end
