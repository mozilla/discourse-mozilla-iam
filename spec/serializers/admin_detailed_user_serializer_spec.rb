require_relative '../iam_helper'

describe AdminDetailedUserSerializer do
  let(:user) { Fabricate(:user) }
  let(:json) { AdminDetailedUserSerializer.new(user, scope: Guardian.new, root:false).as_json }

  describe "#mozilla_iam" do
    it "should contain 'mozilla_iam' prefixed custom fields" do
      mozilla_iam_one = 'Some IAM data'
      mozilla_iam_two = 'Some more IAM data'

      user.custom_fields['mozilla_iam_one'] = mozilla_iam_one
      user.custom_fields['mozilla_iam_two'] = mozilla_iam_two
      user.save

      mozilla_iam = json[:mozilla_iam]
      expect(mozilla_iam['one']).to eq(mozilla_iam_one)
      expect(mozilla_iam['two']).to eq(mozilla_iam_two)
    end

    it "shouldn't contain non-'mozilla_iam' prefixed custom fields" do
      user.custom_fields['other_custom_fields'] = 'some data'
      user.save

      expect(json[:mozilla_iam]).to be_empty
    end
  end
end
