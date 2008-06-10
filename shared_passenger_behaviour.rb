module SharedPassengerBehaviour
  include OSX
  
  USERS_APACHE_PASSENGER_APPS_DIR = "/etc/apache2/users/#{OSX.NSUserName}-passenger-apps"
  USERS_APACHE_CONFIG = "/etc/apache2/users/#{OSX.NSUserName}.conf"
  
  def execute(command)
    script = NSAppleScript.alloc.initWithSource("do shell script \"#{command}\" with administrator privileges")
    script.performSelector_withObject("executeAndReturnError:", nil)
  end
  
  def p(obj)
    NSLog(obj.inspect)
  end
end