# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get '/issues/:id/share', to: 'issue_emails#new'
post '/issues/:id/share', to: 'issue_emails#create'