require_relative '../../iam_helper'

describe MozillaIAM::API do

  describe "profile_apis" do

    context "when classes are defined under MozillaIAM::API" do

      it "only returns those with a ::Profile class defined" do
        class MozillaIAM::API::WithProfile
          class Profile
          end
        end

        class MozillaIAM::API::AlsoWithProfile
          class Profile
          end
        end

        class MozillaIAM::API::WithProfileModule
          module Profile
          end
        end

        class MozillaIAM::API::WithoutProfile
        end

        expect(described_class.profile_apis).to include(MozillaIAM::API::WithProfile)
        expect(described_class.profile_apis).to include(MozillaIAM::API::AlsoWithProfile)
        expect(described_class.profile_apis).not_to include(MozillaIAM::API::WithProfileModule)
        expect(described_class.profile_apis).not_to include(MozillaIAM::API::WithoutProfile)


        remove_consts(
          [:WithProfile, :AlsoWithProfile, :WithProfileModule, :WithoutProfile],
          MozillaIAM::API
        )
      end

    end

  end

end
