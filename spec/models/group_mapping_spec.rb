require_relative '../iam_helper'

describe MozillaIAM::GroupMapping do
  it 'should be destroyed when associated group is destroyed' do
    group = Fabricate(:group)
    mapping = MozillaIAM::GroupMapping.new(iam_group_name: 'iam_group', group: group)
    mapping.save!
    mapping.reload

    expect(mapping).to be
    expect(mapping.group).to be

    mapping.group.destroy!

    expect(MozillaIAM::GroupMapping.first).to be_nil
  end
end
