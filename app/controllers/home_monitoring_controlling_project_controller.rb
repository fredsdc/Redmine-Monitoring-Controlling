class HomeMonitoringControllingProjectController < ApplicationController
  unloadable

  layout 'base'
  before_action :find_project, :authorize
  menu_item :redmine_monitoring_controlling

  def index
    #get main project
    @project = Project.find_by_identifier(params[:id])

    #get projects and sub projects
    array_projects_subprojects = [@project.id] + @project.descendants.pluck(:id)

    @all_project_issues = Issue.select{|i| array_projects_subprojects.include? i.project_id}

    # total issues from the project and subprojects
    @totalIssues = @all_project_issues.count

    #get count of issues by category
    @issuesbycategory = Tracker.find(Issue.where(project_id: array_projects_subprojects).pluck(:tracker_id)).map{|t| {
      name: t.name,
      position: t.position,
      totalbycategory: Issue.where(project_id: array_projects_subprojects, tracker_id: t.id).count,
      totaldone: Issue.where(project_id: array_projects_subprojects, tracker_id: t.id).select{|i| i.closed?}.count,
      totalundone: Issue.where(project_id: array_projects_subprojects, tracker_id: t.id).reject{|i| i.closed?}.count}}

    #get statuses used in project and subprojects
    if @totalIssues > 0
      @statuses = []
      Project.where(id: array_projects_subprojects).each do |p|
        @statuses |= IssueStatus.where(:id =>
          WorkflowTransition.where(:workspace_id => p[:workspace_id], :role_id => p.users_by_role.map{|x| x[0][:id]}, :tracker_id => p.trackers.map(&:id)).map(&:old_status_id) +
          WorkflowTransition.where(:workspace_id => p[:workspace_id], :role_id => p.users_by_role.map{|x| x[0][:id]}, :tracker_id => p.trackers.map(&:id)).map(&:new_status_id)
        ).to_a
      end
    else
      @statuses = nil
    end

    #get management issues by main project
    @managementissues = [
      {id:1, typemanagement: "#{t :manageable_label}",
       totalissues: Issue.where(project_id: array_projects_subprojects).select{|i| i.due_date.present?}.count},
      {id:2, typemanagement: "#{t :unmanageable_label}",
       totalissues: Issue.where(project_id: array_projects_subprojects).reject{|i| i.due_date.present?}.count}
     ]

    #get overdue issues for char by by project and subprojects
    @overdueissueschart = [
      {id:1, typeissue: "#{t :delivered_label}",
       totalissuedelayed: Issue.where(project_id: array_projects_subprojects).
                                select{|i| ! i.due_date.nil? && i.closed?}.count},
      {id:2, typeissue: "#{t :overdue_label}",
       totalissuedelayed: Issue.where(project_id: array_projects_subprojects).
                                select{|i| ! i.due_date.nil? && i.due_date < Date.today && ! i.closed?}.count},
      {id:3, typeissue: "#{t :tobedelivered_label}",
       totalissuedelayed: Issue.where(project_id: array_projects_subprojects).
                                select{|i| ! i.due_date.nil? && i.due_date >= Date.today && ! i.closed?}.count}
    ]

    #get overdueissues by project and subprojects
    @overdueissues = Issue.where(project_id: array_projects_subprojects).order(:due_date).
                           select{|i| ! i.due_date.nil? && i.due_date < Date.today && ! i.closed?}

    #get unmanagement issues by main project
    @unmanagementissues = Issue.where(project_id: array_projects_subprojects).order(:id).
                           select{|i| i.due_date.nil?}
  end

  private
  def find_project
    @project=Project.find(params[:id])
  end
end
