require File.expand_path('../test_helper', __FILE__)
require 'file_backup_and_open'

describe "File::backup_and_open" do
  before do
    create_tmp
    
    @tmp_file = File.join(@tmp, 'testfile.txt')
    @backup = File.join(@tmp, 'testfile.txt.bak')
    
    create_tmp_file
  end
  
  after do
    remove_tmp
  end
  
  it "should create a backup of the file in the same directory as the file" do
    remove_tmp
    FileUtils.stubs(:rm)
    create_tmp
    create_tmp_file
    
    File.should.exist @backup
    File.read(@backup).should == 'line1'
  end
  
  it "should open the file for writing and write the data that's given" do
    File.read(@tmp_file).should == "line1\nline2"
  end
  
  it "should not try to backup the file if it doesn't exist yet" do
    remove_tmp
    create_tmp
    
    File.backup_and_open(@tmp_file, 'a', "line1")
    File.should.not.exist @backup
    File.read(@tmp_file).should == 'line1'
  end
  
  it "should check if everything went according to plan after writing the file and if so remove the backup" do
    File.expects(:read).with(@tmp_file).returns("line1\nline2\nline3").times(2)
    File.backup_and_open(@tmp_file, 'a', "\nline3")
    File.should.not.exist @backup
  end
  
  it "should place the backup back and raise an exception if something went wrong while writing" do
    # This is because FileUtils::cp internally uses File::open.
    FileUtils.stubs(:cp).with do |from, to|
      `cp #{from} #{to}`
    end
    
    # Simulate a write operation going horribly wrong, i.e. emptying the file.
    File.stubs(:open).with do |file, mode|
      FileUtils.rm @tmp_file
      `touch #{@tmp_file}`
    end
    
    lambda { File.backup_and_open(@tmp_file, 'a', "\nline3") }.should.raise File::FileNotSuccesfullyWrittenError
    `cat #{@tmp_file}`.should == "line1\nline2"
  end
  
  it "should remove a string from a file" do
    FileUtils.stubs(:rm)
    
    File.backup_and_remove_data(@tmp_file, 'line1')
    File.read(@tmp_file).should == "\nline2"
    File.read(@backup).should == "line1\nline2"
  end
  
  it "should remove the backup if removing data succeeded" do
    File.backup_and_remove_data(@tmp_file, 'line1')
    File.should.not.exist @backup
  end
  
  it "should place the backup backup and raise an exception if something went wrong while removing" do
    # This is because FileUtils::cp internally uses File::open.
    FileUtils.stubs(:cp).with do |from, to|
      `cp #{from} #{to}`
    end
    
    # Simulate a write operation going horribly wrong, i.e. emptying the file.
    File.stubs(:open).with do |file, mode|
      FileUtils.rm @tmp_file
      `touch #{@tmp_file}`
    end
    
    lambda { File.backup_and_remove_data(@tmp_file, "line1") }.should.raise File::FileNotSuccesfullyWrittenError
    `cat #{@tmp_file}`.should == "line1\nline2"
  end
  
  private
  
  def create_tmp_file
    File.open(@tmp_file, 'w') {|f| f << 'line1' }
    File.backup_and_open(@tmp_file, 'a', "\nline2")
  end
  
  def create_tmp
    @tmp = File.expand_path('../tmp')
    FileUtils.mkdir_p @tmp
  end
  
  def remove_tmp
    FileUtils.rm_rf @tmp
  end
end