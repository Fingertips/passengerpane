module SharedPassengerBehaviour
  include OSX
  
  PASSENGER_APPS_DIR = "/private/etc/apache2/passenger_pane_vhosts"
  
  def execute(command, *args)
    OSX::SecurityHelper.sharedInstance.executeCommand_withArgs(command, args)
  end
  module_function :execute
  
  def p(obj)
    NSLog(obj.is_a?(String) ? obj : obj.inspect)
  end
  module_function :p
end