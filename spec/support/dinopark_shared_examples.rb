shared_examples "dinopark refresh method" do |method_name, attribute_name|
  describe described_class.refresh_methods do
    it { should include(method_name) }
  end

  describe "##{method_name}" do
    let(:user) { Fabricate(:user) }
    let(:profile) { MozillaIAM::Profile.new(user, "uid") }
    include_context "shared context"

    context "with dinopark_enabled? set to false" do
      before do
        profile.dinopark_enabled = false
        profile.expects(:attr).with(attribute_name).never
      end

      include_examples "no change"
    end

    context "with dinopark_enabled? set to true" do
      before do
        profile.dinopark_enabled = true
      end

      context "with nil dinopark #{attribute_name}" do
        before do
          profile.expects(:attr).with(attribute_name).returns(nil)
        end

        include_examples "undefines"
      end

      context "with empty dinopark #{attribute_name}" do
        before do
          profile.expects(:attr).with(attribute_name).returns(" ")
        end

        include_examples "undefines"
      end

      context "with dinopark #{attribute_name} already set" do
        include_context "with attribute already set"

        include_examples "no change"
      end

      include_examples "with dinopark_enabled? set to true"
    end
  end
end
