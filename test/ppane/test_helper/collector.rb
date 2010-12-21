class Collector
  attr_reader :written
  
  def initialize
    @written = []
  end
  
  def write(string)
    @written << string
  end
  
  def puts(string)
    @written << "#{string}\n"
  end
end