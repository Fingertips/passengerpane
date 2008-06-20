module SharedPassengerBehaviour
  include OSX
  
  PASSENGER_APPS_DIR = "/private/etc/apache2/passenger_pane_vhosts"
  
  def execute(command, *args)
    if OSX::SecurityHelper.sharedInstance.executeCommand_withArgs(command, args) == 0
      alert = OSX::NSAlert.alloc.init
      alert.messageText = 'Something went wrong while trying to save your changes'
      alert.informativeText = "Please check your console.log for further info and file a bug report  if it is a bug at:\nhttp://fingertips.lighthouseapp.com/projects/13022"
      alert.objc_send(
        :beginSheetModalForWindow, PrefPanePassenger.sharedInstance.mainView.window,
        :modalDelegate, nil,
        :didEndSelector, nil,
        :contextInfo, nil
      )
      false
    else
      true
    end
  end
  module_function :execute
  
  def p(obj)
    NSLog(obj.is_a?(String) ? obj : obj.inspect)
  end
  module_function :p
end