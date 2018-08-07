module MozillaIAM
  module AdminDetailedUserSerializerExtensions

    def mozilla_iam
      object.custom_fields.select do |k, v|
        k.start_with?('mozilla_iam')
      end.map do |k, v|
        [k.sub('mozilla_iam_', ''), v]
      end.to_h
    end

  end
end
