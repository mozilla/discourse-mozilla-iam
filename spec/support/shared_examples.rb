shared_examples "mozilla_iam in serializer" do
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

  it "should return registered custom fields as arrays" do
    MozillaIAM::Profile.stubs(:array_keys).returns([:array])

    user.custom_fields['mozilla_iam_array'] = "element"

    mozilla_iam = json[:mozilla_iam]
    expect(mozilla_iam['array']).to eq ["element"]
  end
end
