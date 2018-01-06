UserSerializer.attributes :secondary_emails
UserSerializer.send :alias_method, :include_secondary_emails?, :include_email?
