module ApplicationHelper
  def is_editor?
    controller.controller_name == 'scripts' && controller.action_name == 'edit'
  end
end
