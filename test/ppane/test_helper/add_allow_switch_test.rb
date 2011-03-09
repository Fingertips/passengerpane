begin
  require 'rubygems'
rescue LoadError
end

gem 'test-spec'
require 'test/spec'

$:.unshift(File.expand_path('../', __FILE__))
require 'add_allow_switch'

SILENT_COMMAND = 'ls > /dev/null'

module Factory
  def self.run
    true
  end
  
  def self.ran(name, &block)
    block.call("#{name} was run")
  end
end
Factory.add_allow_switch :run, :default => true
Factory.add_allow_switch :ran

describe "Factory with an allow switch on run" do
  it "should alias the original method" do
    Factory.respond_to?(:_run_before_allow_switch, include_private=true).should == true
  end
  
  it "should define a getter and setter" do
    Factory.should.respond_to(:allow_run)
    Factory.should.respond_to(:allow_run=)
  end
  
  it "should switch off" do
    Factory.allow_run = false
    lambda {
      Factory.run
    }.should.raise(RuntimeError)
  end
  
  it "should switch on" do
    Factory.allow_run = true
    lambda {
      Factory.run.should == true
    }.should.not.raise
  end
  
  it "should forward passed blocks and arguments" do
    Factory.allow_ran = true
    Factory.ran('Machine') do |name|
      name + '!'
    end.should == 'Machine was run!'
  end
end

class Bunny
  def hip(name, &block)
    block.call("#{name} is hip")
  end
  
  def hop
    'Hop hop!'
  end
end
Bunny.add_allow_switch :hip
Bunny.add_allow_switch :hop

describe "Bunny with an allow switch on hop" do
  before do
    @bunny = Bunny.new
  end
  
  it "should alias the original method" do
    @bunny.respond_to?(:_hop_before_allow_switch).should == true
  end
  
  it "should define a getter and setter" do
    Bunny.should.respond_to(:allow_hop)
    Bunny.should.respond_to(:allow_hop=)
    
    Bunny.allow_hop.should == false
    Bunny.allow_hop = true
    Bunny.allow_hop.should == true
    Bunny.allow_hop = false
  end
  
  it "should switch off" do
    Bunny.allow_hop = false
    lambda {
      @bunny.hop
    }.should.raise(RuntimeError)
  end
  
  it "should switch on" do
    Bunny.allow_hop = true
    lambda {
      @bunny.hop.should == 'Hop hop!'
    }.should.not.raise
    Bunny.allow_hop = false
  end
  
  it "should forward passed blocks and arguments" do
    Bunny.allow_hip = true
    @bunny.hip('Bunny') do |name|
      name + '!'
    end.should == 'Bunny is hip!'
    Bunny.allow_hop = false
  end
end

Kernel.add_allow_switch :system

describe "Kernel with an allow switch on system" do
  it "should alias the original method" do
    Kernel.respond_to?(:_system_before_allow_switch, include_private=true).should == true
  end
  
  it "should define a getter and setter" do
    Kernel.should.respond_to(:allow_system)
    Kernel.should.respond_to(:allow_system=)
  end
  
  it "should switch off" do
    Kernel.allow_system = false
    lambda {
      system(SILENT_COMMAND)
    }.should.raise(RuntimeError)
    Kernel.allow_system = false
  end
  
  it "should switch on" do
    Kernel.allow_system = true
    lambda {
      system(SILENT_COMMAND)
    }.should.not.raise
    Kernel.allow_system = false
  end
end

Kernel.add_allow_switch :`

describe "Kernel with an allow switch on `" do
  it "switches off" do
    Kernel.allow_backtick = false
    lambda {
      `#{SILENT_COMMAND}`
    }.should.raise(RuntimeError)
  end
end