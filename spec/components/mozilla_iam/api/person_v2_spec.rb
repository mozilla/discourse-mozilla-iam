require_relative "../../../iam_helper"

describe MozillaIAM::API::PersonV2 do
  let(:api) { described_class.new }
  before do
    SiteSetting.mozilla_iam_person_v2_api_url = "https://personv2.com"
    SiteSetting.mozilla_iam_person_v2_api_aud = "personv2.com"
  end

  context "#initialize" do
    it "sets url and aud based on SiteSetting" do
      expect(api.instance_variable_get(:@url)).to eq "https://personv2.com/v2"
      expect(api.instance_variable_get(:@aud)).to eq "personv2.com"
    end
  end

  context "#profile" do
    it "returns the profile for a specific user" do
      api.expects(:get).with("user/user_id/uid").returns(profile: "profile")
      expect(api.profile("uid").instance_variable_get(:@raw)).to eq({profile: "profile"})
    end

    it "returns an empty hash if a profile doesn't exist" do
      api.expects(:get).with("user/user_id/uid").returns({})
      expect(api.profile("uid").instance_variable_get(:@raw)).to eq({})
    end
  end

  describe described_class::Profile do
    def single_attribute(value=nil, metadata={})
      metadata[:verified] = true if metadata[:verified].nil?
      metadata[:public] = true if metadata[:public].nil?
      {
        metadata: {
          verified: metadata[:verified],
          display: metadata[:public] ? "public" : "staff"
        },
        value: value
      }
    end

    def profile_with(attributes, value=nil, metadata={})
      raw = {}
      if attributes.is_a? Hash
        attributes.each do |name, value|
          raw[name] = single_attribute(value)
        end
      else
        raw[attributes] = single_attribute(value, metadata)
      end
      described_class.new(raw)
    end

    shared_examples "one-to-one mapping" do |method, attribute, value|
      describe "##{method}" do
        context "with no #{attribute} attribute" do
          let(:profile) { described_class.new({}) }

          it "returns nil" do
            expect(profile.public_send(method)).to be_nil
          end
        end

        context "with unverified #{attribute} attribute" do
          let(:profile) { profile_with(attribute, value, verified: false) }

          it "returns nil" do
            expect(profile.public_send(method)).to be_nil
          end
        end

        context "with non-public #{attribute} attribute" do
          let(:profile) { profile_with(attribute, value, public: false) }

          it "returns nil" do
            expect(profile.public_send(method)).to be_nil
          end
        end

        let(:profile) { profile_with(attribute, value) }

        it "returns #{attribute}" do
          expect(profile.public_send(method)).to eq value
        end
      end
    end

    include_examples "one-to-one mapping", :username, :primary_username, "janedoe"
    include_examples "one-to-one mapping", :pronouns, :pronouns, "she/her"
    include_examples "one-to-one mapping", :fun_title, :fun_title, "Fun job title"
    include_examples "one-to-one mapping", :description, :description, "I have a fun job"
    include_examples "one-to-one mapping", :location, :location, "Somewhere"

    describe "#full_name" do
      let(:profile) do
        profile_with ({
          first_name: "Jane",
          last_name: "Doe",
          alternative_name: "Janette Smith"
        })
      end

      it "returns first_name + last_name" do
        expect(profile.full_name).to eq "Jane Doe"
      end

      context "without first_name" do
        let(:profile) do
          profile_with ({
            last_name: "Doe",
            alternative_name: "Janette Smith"
          })
        end

        it "returns alternative_name" do
          expect(profile.full_name).to eq "Janette Smith"
        end

        context "without alternative_name" do
          let(:profile) do
            profile_with ({
              last_name: "Doe"
            })
          end

          it "returns last_name" do
            expect(profile.full_name).to eq "Doe"
          end
        end
      end

      context "without last_name" do
        let(:profile) do
          profile_with ({
            first_name: "Jane",
            alternative_name: "Janette Smith"
          })
        end

        it "returns alternative_name" do
          expect(profile.full_name).to eq "Janette Smith"
        end

        context "without alternative_name" do
          let(:profile) do
            profile_with ({
              first_name: "Jane"
            })
          end

          it "returns first_name" do
            expect(profile.full_name).to eq "Jane"
          end
        end
      end

      context "without first_name, last_name or alternative_name" do
        let(:profile) do
          profile_with({})
        end

        it "returns nil" do
          expect(profile.full_name).to be_nil
        end
      end
    end
  end
end
