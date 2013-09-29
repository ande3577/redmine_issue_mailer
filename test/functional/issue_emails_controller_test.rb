require File.expand_path('../../test_helper', __FILE__)

class IssueEmailsControllerTest < ActionController::TestCase
  fixtures :issues, :users, :projects, :members, :member_roles, :journals, 
    :journal_details, :roles
  
  def setup
    @issue = Issue.find(2)
    @admin = User.find(1)
    @user = User.find(2)
    @issue.project.enabled_module_names = [:issue_tracking, :issue_mailer]
    @journal = Journal.find(3)
    flash[:error] = nil # make sure nothing left over from past tests
    ActionMailer::Base.deliveries.clear
    Setting.plugin_redmine_issue_mailer['allowed_domains'] = nil
  end
  
  # Replace this with your real tests.
  def test_invalid_issue_id
    get_admin()
    post :create, :id => 99
    assert_response :missing
  end
  
  def test_new
    get_user()
    add_permission()
    get :new, :id => @issue.id
    assert_response 200
    assert_template :new
    assert_equal @issue, assigns('issue')
    assert_equal @issue.project, assigns('project')
  end
  
  def test_create_without_permission
    get_user()
    post :create, :id => @issue.id
    assert_response 403
  end
  
  def test_send_email_without_address
    get_user()
    add_permission()
    post :create, :id => @issue.id
    assert_response 200
    assert flash[:error]
    assert_template :new
  end
  
  def test_send_email_with_invalid_address
    get_user()
    add_permission()
    post :create, :id => @issue.id, :address => 'sb.com'
    assert_response 200
    assert flash[:error]
    assert_template :new
    assert 'sb.com', assigns('address')
  end
  
  def test_send_email_with_permission
    get_user()
    add_permission()
    @issue.update_attribute(:author_id, @admin.id)
    
    post :create, :id => @issue.id, :address => 's@b.com', :notes => 'a note added to the e-mail'
    assert_redirected_to :controller => :issues, :action => :show,:id => @issue.id
    assert_nil flash[:error]
    
    assert_equal @issue, assigns('issue')
    assert_equal @issue.project, assigns('project')
    
    assert_equal 's@b.com', assigns('address')
    assert_equal ['s@b.com'], assigns('addresses')

    #validate that email was sent
    assert !ActionMailer::Base.deliveries.empty?
    email = ActionMailer::Base.deliveries.last
    
    if Setting.bcc_recipients?
      assert_equal ['s@b.com'], email.bcc
    else
      assert_equal ['s@b.com'], email.to  
    end
    
    assert_mail_body_match @issue.subject, email
    # @bug assert message not supported in redmine 2.3
    assert_include "Issue \##{@issue.id} has been sent to you by #{User.current.name}.", mail_body(email)
    assert_not_include "You have received this notification because you have either subscribed to it, or are involved in it.", mail_body(email) # "make sure the default footer is removed"
    assert_not_include @journal.notes, mail_body(email)
    assert_include 'a note added to the e-mail', mail_body(email)
  end
  
  def test_send_to_multiple_addresses
    get_user()
    add_permission()
    post :create, :id => @issue.id, :address => 's@b.com, a@b.com'
    
    assert_equal 's@b.com, a@b.com', assigns('address')
    assert_equal ['s@b.com', 'a@b.com'], assigns('addresses')
    
    assert !ActionMailer::Base.deliveries.empty?
    email = ActionMailer::Base.deliveries.last
    
    if Setting.bcc_recipients?
      assert_equal ['s@b.com', 'a@b.com'], email.bcc
    else
      assert_equal ['s@b.com', 'a@b.com'], email.to  
    end
  end
  
  def test_send_as_anonymous
    Role.find(5).add_permission! :email_an_issue
    
    post :create, :id => @issue.id, :address => 's@b.com', :notes => 'a note added to the e-mail'
    assert_redirected_to :controller => :issues, :action => :show,:id => @issue.id
    
    #validate that email was sent
    assert !ActionMailer::Base.deliveries.empty?
    email = ActionMailer::Base.deliveries.last
    
    assert_include "Issue \##{@issue.id} has been sent to you.", mail_body(email)
  end
  
  def test_send_with_second_address_invalid
    get_user()
    add_permission()
    post :create, :id => @issue.id, :address => 's@b.com, ab.com'
    assert_response 200
    assert flash[:error]
    assert_template :new
    assert_equal 's@b.com, ab.com', assigns('address')
  end
  
  def test_send_to_multiple_allowed_domains
    get_user()
    add_permission()
    Setting.plugin_redmine_issue_mailer['allowed_domains'] = 'b.com, c.com'
    post :create, :id => @issue.id, :address => 's@b.com, a@c.com'
    
    assert_equal 's@b.com, a@c.com', assigns('address')
    assert_equal ['s@b.com', 'a@c.com'], assigns('addresses')
    
    assert !ActionMailer::Base.deliveries.empty?
    email = ActionMailer::Base.deliveries.last
    
    if Setting.bcc_recipients?
      assert_equal ['s@b.com', 'a@c.com'], email.bcc
    else
      assert_equal ['s@b.com', 'a@c.com'], email.to  
    end
  end
  
  def test_send_to_disallowed_domain
    get_user()
    add_permission()
    Setting.plugin_redmine_issue_mailer['allowed_domains'] = 'b.com, c.com'
    post :create, :id => @issue.id, :address => 's@b.com, a@d.com'
    assert_response 200
    assert flash[:error]
    assert_template :new
    assert_equal 's@b.com, a@d.com', assigns('address')
  end
  
  def test_send_issue_history
    get_user()
    add_permission()
    post :create, :id => @issue.id, :address => 's@b.com', :include_history => 'all_history'
    assert_redirected_to :controller => :issues, :action => :show,:id => @issue.id
    email = ActionMailer::Base.deliveries.last
    assert_include @journal.notes, mail_body(email)
  end
  
  def test_send_comments_only_includes_journal_with_notes
    get_user()
    add_permission()
    post :create, :id => @issue.id, :address => 's@b.com', :include_history => 'comments_only'
    assert_redirected_to :controller => :issues, :action => :show,:id => @issue.id
    email = ActionMailer::Base.deliveries.last
    assert_include @journal.notes, mail_body(email)
  end
  
  def test_send_comments_only_does_not_include_journal_without_notes
    get_user()
    add_permission()
    @journal.notes = nil
    @journal.save!
    @journal.reload()
    
    post :create, :id => @issue.id, :address => 's@b.com', :include_history => 'comments_only'
    assert_redirected_to :controller => :issues, :action => :show,:id => @issue.id
    email = ActionMailer::Base.deliveries.last
    assert_not_include 'Activity', mail_body(email)
  end
  
  def test_does_not_send_private_notes
    get_user()
    add_permission()
    @journal.private_notes = true
    @journal.save!
    @journal.reload()
    
    post :create, :id => @issue.id, :address => 's@b.com', :include_history => 'all_history'
    assert_redirected_to :controller => :issues, :action => :show,:id => @issue.id
    email = ActionMailer::Base.deliveries.last
    assert_not_include 'Activity', mail_body(email)
  end
  
  def test_send_to_self
    get_user()
    add_permission()
    
    @user.pref.update_attribute :no_self_notified, true
    
    post :create, :id => @issue.id, :address => @user.mail
    assert_redirected_to :controller => :issues, :action => :show,:id => @issue.id
    
    assert !ActionMailer::Base.deliveries.empty?
    email = ActionMailer::Base.deliveries.last
    
    if Setting.bcc_recipients?
      assert_equal [@user.mail], email.bcc
    else
      assert_equal [@user.mail], email.to  
    end
  end
  
  def test_parse_out_name_email_address
    get_user()
    add_permission()
    
    post :create, :id => @issue.id, :address => 'Test Developer <s@b.com>'
    assert_redirected_to :controller => :issues, :action => :show, :id => @issue.id
    email = ActionMailer::Base.deliveries.last
    
    if Setting.bcc_recipients?
      assert_equal ['s@b.com'], email.bcc
    else
      assert_equal ['s@b.com'], email.to  
    end
  end
  
  def test_get_users
    get_user()
    add_permission()
    
    get :users, :id => @issue.id, :format => :js
    assert_response 200
    assert_equal User.active.sorted.all, assigns('users')
  end
  
  def test_add_users
    get_user()
    add_permission()
    
    post :add_users, :id => @issue.id, :user_ids => [ @user.id.to_s, @admin.id.to_s ], :format => :js
    assert_response 200
    assert_equal "#{@user.name} <#{@user.mail}>, #{@admin.name} <#{@admin.mail}>", assigns(:email_string)
  end
  
  def test_add_users_none
    get_user()
    add_permission()
    
    post :add_users, :id => @issue.id, :format => :js
    assert_response 200
    assert_equal "", assigns(:email_string)
  end
  
  private
  def get_admin()
    @request.session[:user_id] = @admin.id
  end
  
  def get_user()
    @request.session[:user_id] = @user.id
  end
  
  def add_permission()
    Role.find(1).add_permission! :email_an_issue
  end
end
