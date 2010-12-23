module Kernel
  def trust(value)
    value = value.dup if value.frozen?
    value = value.untaint if value.tainted?
    value
  end
end