module AllowSwitch
  def self.replacement_method_code(object, method, accessor)
    temp_method = "_#{accessor}_before_allow_switch"
    %{
alias_method :#{temp_method}, :#{method}
def #{method}(*args, &block)
  if #{object}.allow_#{accessor}
    #{temp_method}(*args, &block)
  else
    raise RuntimeError, "You're trying to call `#{method}' on `#{object}', which you probably don't want in a test."
  end
end
    }.strip
  end
  
  def self.allow_switch_accessor(accessor)
    allow = "allow_#{accessor}"
    %{
def self.#{allow}
  @#{allow}
end

def self.#{allow}=(value)
  @#{allow} = value
end
    }.strip
  end
  
  def self.switch_accessor(method)
    if method.to_s == "`"
      'backtick'
    else
      method.to_sym
    end
  end
end


class Class
  def add_allow_switch(method, options={})
    default = options[:default] || false
    accessor = AllowSwitch.switch_accessor(method)
    class_eval AllowSwitch.allow_switch_accessor(accessor)
    self.send("allow_#{accessor}=", default)
    class_eval AllowSwitch.replacement_method_code(self, method, accessor)
  end
end

class Module
  def add_allow_switch(method, options={})
    default = options[:default] || false
    accessor = AllowSwitch.switch_accessor(method)
    eval AllowSwitch.allow_switch_accessor(accessor)
    self.send("allow_#{accessor}=", default)
    replacement_method_code = AllowSwitch.replacement_method_code(self, method, accessor)
    if respond_to?(method)
      (class << self; self; end).class_eval(replacement_method_code)
    end
    if self.methods.include?('system')
      class_eval(replacement_method_code)
    end
  end
end