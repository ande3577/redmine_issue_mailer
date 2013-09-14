# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get '/issues/:id/share', to: 'issue_emails#new'
post '/issues/:id/share', to: 'issue_emails#create'
get '/issues/:id/share/users', to: 'issue_emails#users'
post '/issues/:id/share/add_users', to: 'issue_emails#add_users'