require File.expand_path('../test_helper', __FILE__)

ObjectiveC.require('app/models/Application')

DATA = {
  'host' => 'fries.local',
  'aliases' => 'assets.fries.local',
  'path' => '/Users/Fred/code/fries',
  'environment' => 'development',
  'framework' => 'rails'
}

describe "Application" do
  before do
    @data = DATA
  end
  
  it "initializes with blank values" do
    application = OSX::Application.alloc.init
    application.host.should == ''
    application.path.should == ''
    application.framework.should == 'rails'
    application.environment.should == 'development'
    application.vhostAddress.should == '*:80'
    application.userDefinedData.should == ''
    application.isDirty.should == NO
    application.isValid.should == NO
  end
  
  it "initializes with a dictionary" do
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

describe "Application, concerning validation" do
  before do
    @data = DATA
  end
  
  it "it requires a host and path" do
    application = OSX::Application.alloc.init
    application.isValid.should == NO
    
    application.setValue_forKey(@data['host'], 'host')
    application.setValue_forKey(@data['path'], 'path')
    application.isValid.should == YES
    
    application.setValue_forKey('', 'host')
    application.isValid.should == NO
    
    application.setValue_forKey(@data['host'], 'host')
    application.setValue_forKey('', 'path')
    application.isValid.should == NO
  end
end