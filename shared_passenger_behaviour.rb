module SharedPassengerBehaviour
  include OSX
  
  USERS_APACHE_PASSENGER_APPS_DIR = "/etc/apache2/users/#{OSX.NSUserName}-passenger-apps"
  USERS_APACHE_CONFIG = "/etc/apache2/users/#{OSX.NSUserName}.conf"
  
  def execute(command)
    apple_script "do shell script \"#{command}\" with administrator privileges"
  end
  
  def apple_script(command)
    script = NSAppleScript.alloc.initWithSource(command)
    script.performSelector_withObject("executeAndReturnError:", nil)
  end
  
  def p(obj)
    NSLog(obj.is_a?(String) ? obj : obj.inspect)
  end
end