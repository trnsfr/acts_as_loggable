module LogFilters
  
  def record_user_login
    current_account = Activity.current_account
    current_user = Activity.current_user
    user = Activity.user
    Activity.create(:logged_by => user,
                    :account_id => current_account,
                    :note => user + " logged in", 
                    :loggable_type => "User", 
                    :loggable_id => current_user)
  end
  
end
