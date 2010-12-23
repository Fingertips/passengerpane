require File.expand_path('../test_helper', __FILE__)

ObjectiveC.require('app/models/Application')

DATA = {
  'host' => 'fries.local',
  'aliases' => 'assets.fries.local',
  'path' => '/Users/Fred/code/fries',
  'environment' => 'development'
}

describe "Application" do
  before do
    @data = DATA
  end
  
  it "initializes with blank values" do
    application = OSX::Application.alloc.init
    application.host.should == ''
    application.aliases.should == ''
    application.path.should == ''
    application.environment.should == DEVELOPMENT
    application.isDirty.should == NO
    application.isValid.should == NO
    application.isFresh.should == YES
  end
  
  it "initializes with a dictionary" do
    application = OSX::Application.alloc.initWithDictionary(@data)
    application.host.should == @data['host']
    application.aliases.should == @data['aliases']
    application.path.should == @data['path']
    application.environment.should == DEVELOPMENT
    application.isDirty.should == NO
    application.isValid.should == YES
    application.isFresh.should == NO
  end
  
  # it "convert to a dictionary" do
  #   application = OSX::Application.alloc.initWithDictionary(@data)
  #   application.toDictionary.to_ruby.should == @data
  # end
end

# describe "Application, concerning validation" do
#   before do
#     @data = DATA
#   end
#   
#   it "it requires a host and path" do
#     application = OSX::Application.alloc.init
#     application.isValid.should == NO
#     
#     application.setValue_forKey(@data['host'], 'host')
#     application.setValue_forKey(@data['path'], 'path')
#     application.isValid.should == YES
#     
#     application.setValue_forKey('', 'host')
#     application.isValid.should == NO
#     
#     application.setValue_forKey(@data['host'], 'host')
#     application.setValue_forKey('', 'path')
#     application.isValid.should == NO
#   end
# end
# 
# describe "Application, concerning dirty checking" do
#   before do
#     @data = DATA
#     @application = OSX::Application.alloc.initWithDictionary(@data)
#   end
#   
#   it "is not dirty after initialization" do
#     @application.isDirty.should == NO
#   end
#   
#   it "marks itself as dirty when a value changes" do
#     @application.setValue_forKey('changed.local', 'host')
#     @application.isDirty.should == YES
#   end
#   
#   it "is not dirty when a value changed and was reversed" do
#     @application.setValue_forKey('changed.local', 'host')
#     @application.setValue_forKey(@data['host'], 'host')
#     @application.isDirty.should == NO
#   end
# end