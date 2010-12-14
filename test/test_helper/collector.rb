class Collector
  attr_reader :written
  def initialize
    @written = []
  end
  
  def write(string)
    @written << string
  end
end