module SharedPassengerBehaviour
  include OSX
  
  def execute(command, *args)
    if OSX::SecurityHelper.sharedInstance.executeCommand_withArgs(command, args) == 0
      p "The command that failed was: `#{command} #{args.map { |arg| arg.inspect }.join(' ')}'"
      
      alert = OSX::NSAlert.alloc.init
      alert.messageText = 'Your changes couldn’t be saved'
      alert.informativeText = "See the Console log for details.\nYou can file a bug report at:\nhttp://fingertips.lighthouseapp.com/projects/13022"
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