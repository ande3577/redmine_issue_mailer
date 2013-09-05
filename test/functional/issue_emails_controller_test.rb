require File.expand_path('../../test_helper', __FILE__)

class IssueEmailsControllerTest < ActionController::TestCase
  fixtures :issues, :users, :projects, :members, :member_roles
  
  def setup
    @issue = Issue.find(2)
    @admin = User.find(1)
    @user = User.find(2)
    @issue.project.enabled_module_names = [:issue_tracking, :issue_mailer]
    flash[:error] = nil # make sure nothing left over from past tests
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
    post :create, :id => @issue.id, :address => 's@b.com'
    assert_redirected_to :controller => :issues, :action => :show,:id => @issue.id
    assert_nil flash[:error]
    assert_equal @issue, assigns('issue')
    assert_equal @issue.project, assigns('project')

    #validate that email was sent
    assert !ActionMailer::Base.deliveries.empty?
    email = ActionMailer::Base.deliveries.last
    
    if Setting.bcc_recipients?
      assert_equal ['s@b.com'], email.bcc
    else
      assert_equal ['s@b.com'], email.to  
    end
    
    assert_mail_body_match @issue.subject, email
  end
  
  private
  def get_admin()
    @request.session[:user_id] = @admin.id
  end
  
  def get_user()
    @request.session[:user_id] = @user.id
  end
  
  def add_permission()
    Role.find(1).add_permission! :email_an_issue_to_a_non_user
  end
end
