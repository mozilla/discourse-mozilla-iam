Group.class_eval do
  has_many :mappings, class_name: "MozillaIAM::GroupMapping",
                      dependent:  :destroy
end
