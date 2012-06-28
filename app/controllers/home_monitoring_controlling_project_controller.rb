class HomeMonitoringControllingProjectController < ApplicationController
  unloadable

  layout 'base'
  before_filter :find_project, :authorize
  menu_item :redmine_monitoring_controlling

  def index
    #tool instance
    tool = McTools.new
    
    #get main project
    @project = Project.find_by_identifier(params[:id])

    #get projects and sub projects
    stringSqlProjectsSubProjects = tool.return_ids(@project.id)
    
    @projects_subprojects = Project.find_by_sql("select * from projects where id in (#{stringSqlProjectsSubProjects});")
    @all_project_issues = Issue.find_by_sql("select * from issues where project_id in (#{stringSqlProjectsSubProjects});")


    #get statuses by main project and subprojects
    @statuses = IssueStatus.find_by_sql("SELECT *,
                                          ((SELECT COUNT(1) FROM issues where project_id in (#{stringSqlProjectsSubProjects}) and status_id = issue_statuses.id)
                                          /
                                          (SELECT COUNT(1) FROM issues where project_id in (#{stringSqlProjectsSubProjects})))*100 as percent,
                                          (SELECT COUNT(1) FROM issues where project_id in (#{stringSqlProjectsSubProjects}) and status_id = issue_statuses.id)
                                          AS totalissues
                                          FROM issue_statuses where id in
                                          (SELECT new_status_id as issues FROM workflows where role_id in
                                          (SELECT DISTINCT role_id FROM member_roles where member_id in
                                          (SELECT DISTINCT id FROM members where project_id in (#{stringSqlProjectsSubPorjects})))
                                          AND tracker_id in
                                          (SELECT DISTINCT tracker_id FROM projects_trackers where project_id in (#{stringSqlProjectsSubPorjects}))
                                          UNION SELECT old_status_id FROM workflows where role_id in
                                          (SELECT DISTINCT role_id FROM member_roles where member_id in
                                          (SELECT DISTINCT id FROM members where project_id in (#{stringSqlProjectsSubPorjects})))
                                          AND tracker_id in
                                          (SELECT DISTINCT tracker_id FROM projects_trackers where project_id in (#{stringSqlProjectsSubPorjects})));")
                                          

    #get management issues by main project
    @managementissues = Issue.find_by_sql("select 1 as id, '#{t :manageable_label}' as typemanagement, count(1) as totalissues
                                                from issues where project_id in (#{stringSqlProjectsSubProjects}) and due_date is not null
                                                union
                                                select 2 as id, '#{t :unmanageable_label}' as typemanagement, count(1) as totalissues
                                                from issues where project_id in (#{stringSqlProjectsSubProjects}) and due_date is null;")


    #get overdue issues for char by by project and subprojects
    @overdueissueschart = Issue.find_by_sql(["select 2 as id, '#{t :overdue_label}' as typeissue, count(1) as totalissuedelayed
                                                  from issues
                                                  where project_id in (#{stringSqlProjectsSubProjects})
                                                  and due_date is not null
                                                  and due_date <  '#{Date.today}'
                                                  and status_id in (select id from issue_statuses where is_closed = ?)
                                                  union
                                                  select 1 as id, '#{t :delivered_label}' as typeissue, count(1) as totalissuedelayed
                                                  from issues
                                                  where project_id in (#{stringSqlProjectsSubProjects})
                                                  and due_date is not null
                                                  and due_date < '#{Date.today}'
                                                  and status_id in (select id from issue_statuses where is_closed = ?)
                                                  union
                                                  select 3 as id, '#{t :tobedelivered_label}' as typeissue, count(1) as totalissuedelayed
                                                  from issues
                                                  where project_id in (#{stringSqlProjectsSubProjects})
                                                  and due_date is not null
                                                  and due_date >= '#{Date.today}'
                                                  and status_id in (select id from issue_statuses where is_closed = ?)
                                                  order by 1;", false, true, false])


    #get overdueissues by project and subprojects
    @overdueissues   =   Issue.find_by_sql(["select *
                                                    from issues
                                                    where project_id in (#{stringSqlProjectsSubProjects})
                                                    and due_date is not null
                                                    and due_date < '#{Date.today}'
                                                    and status_id in (select id from issue_statuses where is_closed = ? )
                                                    order by due_date;",false])

    #get unmanagement issues by main project
    @unmanagementissues = Issue.find_by_sql("select *
                                             from issues where project_id in (#{stringSqlProjectsSubProjects}) 
                                             and due_date is null
                                             order by 1;")





  end

  private
  def find_project
    @project=Project.find(params[:id])
  end    
end
