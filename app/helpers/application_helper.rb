module ApplicationHelper
  def is_editor?
    controller.controller_name == 'scripts' && controller.action_name == 'editor'
  end

  def script_content_url(script)
    if script.has_content?
      script.content_url
    else
      'https://s3-us-west-1.amazonaws.com/synthdrop/scripts/dc8606ea6d98885e517e898cb60ca304'
    end
  end
end
