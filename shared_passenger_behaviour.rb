module SharedPassengerBehaviour
  include OSX
  
  PASSENGER_APPS_DIR = "/private/etc/apache2/passenger_pane_vhosts"
  #USERS_APACHE_CONFIG = "/etc/apache2/users/#{OSX.NSUserName}.conf"
  
  def execute(command, *args)
    OSX::SecurityHelper.sharedInstance.executeCommand_withArgs(command, args)
  end
  module_function :execute
  
  def p(obj)
    NSLog(obj.is_a?(String) ? obj : obj.inspect)
  end
  module_function :p
end