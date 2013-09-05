class IssueEmailsController < ApplicationController
  unloadable
  
  helper :issues
  
  before_filter :get_issue
  before_filter :get_project
  before_filter :authorize
  before_filter :get_address_from_params


  def new
  end

  def create
    return handle_address_error(l(:issue_mailer_blank_address_error)) if @address.nil? or @address.blank?
    return handle_address_error(l(:issue_mailer_invalid_address_error)) if (@address =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i).nil?

    users = [User.new(:mail => @address)]
    Mailer.issue_add(@issue, [User.new(:mail => @address)], [] ).deliver
    redirect_to :controller => :issues, :action => :show,:id => @issue.id
  end
  
  private
  def get_issue
    begin
      @issue = Issue.find(params[:id])
    rescue
      return render_404
    end
  end
  
  def get_project
    @project = @issue.project
  end
  
  def get_address_from_params
    @address = params[:address]
  end
  
  def handle_address_error(error)
    flash[:error] = error
    new
    render :action => :new
    false 
  end
  
end
