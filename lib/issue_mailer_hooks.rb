# This class hooks into Redmine's View Listeners in order to add content to the page
class IssueMailerHooks < Redmine::Hook::ViewListener
  render_on :view_issues_sidebar_queries_bottom, :partial => 'issues/issue_mailer_show_sidebar_bottom', :layout => false
end
