class IssueEmailsController < ApplicationController
  unloadable
  
  helper :issues
  
  before_filter :get_issue, :get_project, :authorize 
  before_filter :get_address_from_params, :get_journals, :get_notes_from_params, :only => [:new, :create]

  def new
  end

  def create
    users = []
    return handle_address_error(l(:issue_mailer_blank_address_error)) if @addresses.nil? or @addresses.empty?
      
    domains = split_addresses(Setting.plugin_redmine_issue_mailer['allowed_domains'])
    
    @addresses.each do |a|
      address_pattern = /\<[^>]+>/
      if a =~ address_pattern
        a = a[address_pattern]
        a.sub!(/^\</, "")
        a.sub!(/\>$/, "")
      end
      return handle_address_error(l(:issue_mailer_blank_address_error)) if a.nil? or a.blank?
      return handle_address_error(l(:issue_mailer_invalid_address_error)) if (a =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i).nil?
      
      d = a.split('@')[1]
      return handle_address_error(l(:issue_mailer_domain_not_allowed, :domain => d)) if domains and !domains.index(d)
  
      users << User.new(:mail => a)
    end
    IssueMailer.issue_share(@issue, User.current, users, [], @journals, @notes ).deliver
    flash[:notice] = l(:issue_mailer_message_sent)
    redirect_to :controller => :issues, :action => :show,:id => @issue.id
  end
  
  def users
    @users = User.active.sorted.all
    @addresses = params[:addresses]
    respond_to do |format|
      format.js { render layout: false }
    end
  end
  
  def add_users
    users = params[:user_ids]
    users = [users] if users and not params[:user_ids].is_a?(Array)
    @email_string = ""
    unless users.nil?
      users.each do |u|
        begin
          user = User.find(u)
          @email_string << "#{user.name} <#{user.mail}>, "
        rescue
        end  
      end
    end
    @email_string.sub!(/, $/, "")
    @email_string = @email_string.html_safe
    respond_to do |format|
      format.js
    end
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
      
    @addresses = split_addresses(@address)
  end
  
  def get_journals
    @include_history = params[:include_history]
    if any_history?(@include_history)
      @journals = @issue.journals
      @journals.reject!(&:private_notes?) 
      if @include_history == 'comments_only'
        @journals.select! { |j| j.notes and !j.notes.empty? }
      end
    else
      @journals = []
    end
  end
  
  def get_notes_from_params
    @notes = params[:notes]
  end
  
  def handle_address_error(error)
    flash[:error] = error
    new
    render :action => :new
    false 
  end
  
  def split_addresses(str)
    addresses = str.split(",") if str
    addresses.map { |a| a.strip! } if addresses
    addresses
  end
  
  def any_history?(include_history)
    @include_history == 'all_history' or @include_history == 'comments_only'
  end
  
end
