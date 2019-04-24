require_relative '../iam_helper'

describe AdminDetailedUserSerializer do
  let(:user) { Fabricate(:user_with_secondary_email) }
  let(:admin) { Fabricate(:admin) }
  let(:json) { AdminDetailedUserSerializer.new(user, scope: Guardian.new(admin), root:false).as_json }

  describe "#mozilla_iam" do
    include_examples "mozilla_iam in serializer"
  end
end
