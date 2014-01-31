#!/usr/bin/env ruby

require 'rubygems'
require 'pp'
require 'jira'
require 'octokit'

# First `chmod 755 ./migrate-issues.rb`
# Run using `./migrate-issues.rb`

my_repo = "something/repo1"
my_jira_url = "https://something.atlassian.net"
Octokit.configure do |c|
  c.login = 'github-login'
  c.password = 'github-password'
end

# jira config
username = "jira-login"
password = "jira-password"

options = {
    :username => username,
    :password => password,
    :site     => my_jira_url,
    :context_path => '',
    :auth_type => :basic
}

client = JIRA::Client.new(options)

# Show all projects
projects = client.Project.all

# This code can all be customized to how you want to map/migrate things
# Ref: http://developer.github.com/v3/issues/#create-an-issue
# Ref: https://{your-instance}.atlassian.net/rest/api/latest/search
# NB: I copied and pasted the API results from my instance into JSONlint.com to make it 'pretty'
# in order to pick out the fields and take a look at my real data
projects.each do |project|
  if project.key == 'old-project-1' || project.key == 'old-project-2' || project.key == 'old-project-3'
  puts "Project -> key: #{project.key}, name: #{project.name}"
    project.issues.each do |issue|
      # selective mapping to milestone
      if project.key == 'old-project-1'
        milestone = '1'
      else
        milestone = nil
      end
      if issue.status.name == 'Open' || issue.status.name == 'To Do'
        if issue.issuetype.name == 'New Feature' || issue.issuetype.name == 'Task' || issue.issuetype.name == 'Improvement'
          label = 'enhancement'
        else
          label = 'bug'
        end
        if issue.assignee.present? && issue.assignee.name == 'some-user-name'
          assignee = 'github-username1'
        elsif issue.assignee.present? &&  issue.assignee.name == 'some-other-user-name'
          assignee = 'github-username2'
        else
          assignee = nil
        end
        puts "#{issue.id} - #{assignee} - #{issue.status.name} - #{label} - #{issue.summary}"
        Octokit.create_issue(my_repo, issue.summary, issue.description, {:assignee => assignee, :milestone => milestone, :labels => label})
      end
    end
  end
end