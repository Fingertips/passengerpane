class SecurityHelper
  def execute(command, *args)
    p "Execute: #{command}, with: #{args}"
  end
  
  private
  
  def p(obj)
    NSLog(obj.is_a?(String) ? obj : obj.inspect)
  end
end