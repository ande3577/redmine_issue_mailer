module RedmineIssueMailerMailerPatch
  def self.included(base)
    unloadable
    
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      # Builds a mail for notifying to_users and cc_users about a new issue
      def issue_share(issue, to_users, cc_users, journals)
        redmine_headers 'Project' => issue.project.identifier,
                        'Issue-Id' => issue.id,
                        'Issue-Author' => issue.author.login
        redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
        message_id issue
        references issue
        @author = issue.author
        @issue = issue
        @journals = journals
        @users = to_users + cc_users
        @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue)
        Setting.emails_footer = l(:text_issue_shared_reason) # suppress the footer message, since the user is not subscribed
        mail :to => to_users.map(&:mail),
          :cc => cc_users.map(&:mail),
          :subject => "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
      end
    end
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
  end
  
end

Mailer.send(:include, RedmineIssueMailerMailerPatch)
