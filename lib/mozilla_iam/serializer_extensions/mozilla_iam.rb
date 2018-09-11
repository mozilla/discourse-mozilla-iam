module MozillaIAM
  module SerializerExtensions
    module MozillaIAM

      def self.included(c)
        c.attributes :mozilla_iam
      end

      def mozilla_iam
        object.custom_fields.select do |k, v|
          k.start_with?('mozilla_iam')
        end.map do |k, v|
          key = k.sub('mozilla_iam_', '')
          val = Array(v) if Profile.array_keys.include?(key.to_sym)
          [key, val || v]
        end.to_h
      end

      def include_mozilla_iam?
        (object&.id == scope.user&.id) || scope.is_staff?
      end

    end
  end
end
