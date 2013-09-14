require_dependency 'issue_mailer_hooks'
require_dependency 'redmine_issue_mailer_mailer_patch'

Redmine::Plugin.register :redmine_issue_mailer do
  
  settings :default => {'allowed_domains' => nil}, :partial => 'settings/issue_mailer_settings'
  
  project_module :issue_mailer do
    permission :email_an_issue, :issue_emails => [ :create, :new, :users, :add_users ]
  end
  
  name 'Redmine Issue Mailer plugin'
  author 'David S Anderson'
  description 'This plugin allows emailing an issue to a user.'
  version '0.0.1'
  url 'https://github.com/ande3577/redmine_issue_mailer'
  author_url 'https://github.com/ande3577'
end
