Auth::Result.prepend MozillaIAM::AuthResultExtensions
Auth::Result.class_eval do
  attr_accessor :user_id
end
