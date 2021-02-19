class McTimeMgmtProjectController < ApplicationController
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

    projectIssues=Issue.where(project_id: array_projects_subprojects, parent_id: nil).where.not(due_date: nil)
    @issuesSpentHours = projectIssues.order(:due_date).pluck(:due_date, :estimated_hours).group_by{|k,v| k}.map{|k,v| [k, {
                          estimated_hours: v.map{|i| i[1].to_i}.reduce(0, :+),
                          sumestimatedhours: projectIssues.where.not(estimated_hours:nil).select{|x| x.due_date <= k}.
                            pluck(:estimated_hours).reduce(0, :+),
                          sumspenthours: TimeEntry.where(project_id: array_projects_subprojects).
                            select{|x| x.spent_on <= k}.pluck(:hours).reduce(0, :+)}]}.to_h

    @spentHoursByVersion = projectIssues.where.not(fixed_version_id: nil).joins(:fixed_version).order("versions.effective_date").
                             pluck(:fixed_version_id, :estimated_hours, :due_date).group_by{|k,v| k}.map{|k,v| [k, {
                               version: Version.find(k).name,
                               effective_date: Version.find(k).effective_date,
                               estimated_hours: v.map{|x| x[1].to_i}.reduce(0, :+),
                               sumestimatedhours: projectIssues.where(fixed_version_id: k).where.not(estimated_hours:nil).
                                 select{|x| x.due_date <= Version.find(k).effective_date}.pluck(:estimated_hours).reduce(0, :+),
                               sumspenthours: TimeEntry.where(project_id: array_projects_subprojects).where.not(issue_id: nil).
                                 select{|x| x.issue.fixed_version_id == k && x.spent_on <= Version.find(k).effective_date}.pluck(:hours).reduce(0, :+)}]}.to_h
  end

  private
  def find_project
    @project=Project.find(params[:id])
  end


end
