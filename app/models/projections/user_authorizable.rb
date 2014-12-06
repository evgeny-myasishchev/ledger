module Projections::UserAuthorizable
  def authorize_user(user_id)  
    return if authorized_user_ids.include?("{#{user_id}}")
    authorized_user_ids_will_change!
    authorized_user_ids << ',' unless authorized_user_ids.empty?
    authorized_user_ids << '{' 
    authorized_user_ids << user_id.to_s
    authorized_user_ids << '}'
  end

  def set_authorized_users(user_ids)
    self.authorized_user_ids = user_ids.map { |id| "{#{id}}" }.join(',')
  end
end