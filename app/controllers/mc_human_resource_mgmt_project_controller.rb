class McHumanResourceMgmtProjectController < ApplicationController
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

    @statusesByAssigneds = Issue.find_by_sql("SELECT assigned_to_id,
                                                (SELECT firstname
                                                FROM users WHERE id = assigned_to_id) AS assigned_name,
                                                issue_statuses.id, issue_statuses.name,
                                                (SELECT COUNT(1) FROM issues i WHERE i.project_id IN (#{stringSqlProjectsSubProjects})
                                                  AND ((i.assigned_to_id = issues.assigned_to_id
                                                      AND i.assigned_to_id IS not null)
                                                      OR (i.assigned_to_id IS null
                                                        AND issues.assigned_to_id IS null))
                                                  AND i.status_id = issue_statuses.id) AS totalassignedbystatuses FROM issues,
                                                issue_statuses WHERE project_id IN (#{stringSqlProjectsSubProjects})
                                                AND issue_statuses.id IN
                                                  (SELECT new_status_id AS issues FROM workflows WHERE role_id IN
                                                    (SELECT DISTINCT role_id FROM member_roles WHERE member_id IN
                                                      (SELECT DISTINCT id FROM members WHERE project_id IN (#{stringSqlProjectsSubProjects})))
                                                  AND tracker_id IN
                                                    (SELECT DISTINCT tracker_id FROM projects_trackers WHERE
                                                    project_id IN (#{stringSqlProjectsSubProjects})) UNION
                                                  SELECT old_status_id FROM workflows WHERE role_id IN
                                                    (SELECT DISTINCT role_id FROM member_roles WHERE member_id IN
                                                      (SELECT DISTINCT id FROM members WHERE project_id IN (#{stringSqlProjectsSubProjects})))
                                                  AND tracker_id IN
                                                    (SELECT DISTINCT tracker_id FROM projects_trackers WHERE
                                                    project_id IN (#{stringSqlProjectsSubProjects}))) GROUP BY assigned_to_id,
                                                assigned_name,
                                                issue_statuses.id,
                                                issue_statuses.name ORDER BY 2,3;")
  end

  private
  def find_project
    @project=Project.find(params[:id])
  end


end