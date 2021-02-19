class McHumanResourceMgmtProjectController < ApplicationController
  unloadable

  layout 'base'
  before_action :find_project, :authorize
  menu_item :redmine_monitoring_controlling

  def index
    #get main project
    @project = Project.find_by_identifier(params[:id])

    #get projects and sub projects
    array_projects_subprojects = [@project.id] + @project.descendants.pluck(:id)

    # total issues from the project and subprojects
    @totalIssues = Issue.where(project_id: array_projects_subprojects).count

    @statusesByAssigneds = Issue.where(project_id: array_projects_subprojects).map{|i| {
      assigned_to_id: i.assigned_to.present? ? i.assigned_to.id : 0,
      assigned_to_name: i.assigned_to.present? ? i.assigned_to.name : "",
      status_id: i.status.id,
      status_name: i.status.name}}
  end

  private
  def find_project
    @project=Project.find(params[:id])
  end


end
