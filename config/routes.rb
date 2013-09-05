# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get '/issues/:id/send', to: 'issue_emails#new'
post '/issues/:id/send', to: 'issue_emails#create'