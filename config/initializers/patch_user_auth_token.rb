UserAuthToken.class_eval do
  has_one :mozilla_iam_session_data,
    class_name: "MozillaIAM::SessionData",
    dependent: :destroy
end
