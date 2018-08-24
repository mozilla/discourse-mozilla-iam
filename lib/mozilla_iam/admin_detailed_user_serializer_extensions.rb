module MozillaIAM
  module AdminDetailedUserSerializerExtensions

    def mozilla_iam
      object.custom_fields.select do |k, v|
        k.start_with?('mozilla_iam')
      end.map do |k, v|
        key = k.sub('mozilla_iam_', '')
        val = Array(v) if Profile.array_keys.include?(key.to_sym)
        [key, val || v]
      end.to_h
    end

  end
end
