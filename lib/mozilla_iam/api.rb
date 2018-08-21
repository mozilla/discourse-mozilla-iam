module MozillaIAM
  module API
    def self.profile_apis
      API.constants
        .map { |x| API.const_get x }
        .select do |x|
          x.kind_of?(Class) &&
          x.const_defined?(:Profile) &&
          x.const_get(:Profile).kind_of?(Class)
        end
    end
  end
end
