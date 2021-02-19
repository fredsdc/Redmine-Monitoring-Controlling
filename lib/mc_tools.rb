class McTools
  # This class holds useful functions
  # user on Monitoring & Controlling plugin

  # return the plugin folder instalation
  def returnPluginFolderName
    if Rails.version.to_f >= 3.0
      File.dirname(__FILE__).gsub(File.join(Rails.root.to_s,'plugins'),'').split('/')[1]
    else
      File.dirname(__FILE__).gsub(File.join(Rails.root.to_s,'vendor','plugins'),'').split('/')[1]
    end
  end

  # return total of tasks with closed flag false
  # done tasks
  def returnTotalOfClosedTasks(project_identifier)
    countTasks(project_identifier, true)
  end
  # done tasks
  def returnTotalOfOpenTasks(project_identifier)
    countTasks(project_identifier, false)
  end

  private
  #count tasks
  def countTasks(project_identifier, isClosed)
    #get main project
    project = Project.find_by_identifier(project_identifier)
    #get projects and sub projects
    array_projects_subprojects = [project.id] + project.descendants.pluck(:id)
    Issue.where(project_id: array_projects_subprojects).select{|i| isClosed ? i.closed? : ! i.closed?}.count
  end
end
