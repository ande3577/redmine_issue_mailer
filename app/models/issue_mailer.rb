class IssueMailer < Mailer
  layout 'issue_mailer'
  
  # Builds a mail for notifying to_users and cc_users about a new issue
  def issue_share(issue, sender, to_users, cc_users, journals, notes)
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id issue
    references issue
    @author = issue.author
    @issue = issue
    @sender = sender
    @journals = journals
    @users = to_users + cc_users
    @notes = notes
    @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)
    # allow sending to self regardless of no self notification
    @author.pref.no_self_notified = false if @author

    mail :to => to_users.map(&:mail),
      :cc => cc_users.map(&:mail),
      :subject => "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
  end
  
end