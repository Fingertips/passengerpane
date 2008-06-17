module SharedPassengerBehaviour
  include OSX
  
  USERS_APACHE_PASSENGER_APPS_DIR = "/etc/apache2/users/#{OSX.NSUserName}-passenger-apps"
  USERS_APACHE_CONFIG = "/etc/apache2/users/#{OSX.NSUserName}.conf"
  
  def execute(command, *args)
    OSX::SecurityHelper.sharedInstance.executeCommand_withArgs(command, args)
  end
  module_function :execute
  
  def p(obj)
    NSLog(obj.is_a?(String) ? obj : obj.inspect)
  end
  module_function :p
end