DiscourseEvent.on(:before_create_notification) do |user, type, post, opts|
  MozillaIAM::Profile.refresh(user) if post.topic.category&.read_restricted
end

refresh_users = lambda do |users, post|
  users.each do |user|
    MozillaIAM::Profile.refresh(user) if post.topic.category&.read_restricted
  end
end

DiscourseEvent.on(:before_create_notifications_for_users, &refresh_users)

DiscourseEvent.on(:notify_mailing_list_subscribers, &refresh_users)
