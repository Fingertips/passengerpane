module SharedPassengerBehaviour
  include OSX
  
  def execute(command)
    script = NSAppleScript.alloc.initWithSource("do shell script \"#{command}\" with administrator privileges")
    script.performSelector_withObject("executeAndReturnError:", nil)
  end
  
  def p(obj)
    NSLog(obj.inspect)
  end
end