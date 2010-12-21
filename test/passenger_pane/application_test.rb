require File.expand_path('../test_helper', __FILE__)

ObjectiveC.require('app/models/Application')

describe "Application" do
  it "allocates with a dictionary" do
    @data = {
      'host' => 'fries.local',
      'aliases' => 'assets.fries.local',
      'path' => '/Users/Fred/code/fries',
      'environment' => 'development',
      'framework' => 'rails'
    }
    application = OSX::Application.alloc.initWithDictionary(@data)
    application.host.should == @data['host']
    application.aliases.should == @data['aliases']
    application.path.should == @data['path']
    application.environment.should == @data['environment']
    application.framework.should == @data['framework']
    application.isDirty.should == NO
    application.isValid.should == YES
  end
end