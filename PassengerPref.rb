require 'osx/cocoa'
include OSX

OSX.require_framework 'PreferencePanes'
OSX.load_bridge_support_file File.expand_path('../Security.bridgesupport', __FILE__)

require File.expand_path('../passenger_pane_config', __FILE__)
require File.expand_path('../shared_passenger_behaviour', __FILE__)
require File.expand_path('../PassengerApplication', __FILE__)

if RUBY_VERSION == "1.8.7" && OSX::RUBYCOCOA_VERSION == "0.13.2"
  class OSX::NSArray
    def count
      oc_count
    end
  end
end

class PrefPanePassenger < NSPreferencePane
  class << self
    attr_accessor :sharedInstance
  end
  
  include SharedPassengerBehaviour
  
  ib_outlet :installPassengerWarning
  ib_outlet :authorizationView
  ib_outlet :applicationsTableView
  ib_outlet :applicationsController
  
  kvc_accessor :applications, :authorized, :dirty_apps, :revertable_apps
  
  def mainViewDidLoad
    self.class.sharedInstance = self
    setup_authorization_view!
    setup_applications_table_view!
    
    OSX::NSNotificationCenter.defaultCenter.objc_send(
      :addObserver, self,
         :selector, 'paneWillBecomeActive:',
             :name, OSX::NSApplicationWillBecomeActiveNotification,
           :object, nil
    )
  end
  
  def paneWillBecomeActive(notification = nil)
    willSelect
  end
  
  def willSelect
    @dropping_directories = @dirty_apps = @revertable_apps = false
    setup_passenger_warning!
    @applicationsController.content.empty? ? load_appications! : reload_appications!
  end
  
  def applicationMarkedDirty(app)
    self.revertable_apps = @applicationsController.content.any? { |app| app.revertable? }
    self.dirty_apps = true
  end
  
  def apply(sender = nil)
    if authorize!
      @applicationsController.content.each { |app| app.apply if app.dirty? }
      self.dirty_apps = self.revertable_apps = false
    else
      p "Unable to #{action} because authorization failed."
    end
  end
  
  def revert(sender = nil)
    @applicationsController.content.each { |app| app.revert if app.revertable? }
    self.dirty_apps = self.revertable_apps = false
  end
  
  def restart(sender = nil)
    @applicationsController.content.each { |app| app.restart unless app.new_app? }
  end
  
  def remove(sender = nil)
    apps = @applicationsController.selectedObjects
    existing_apps = apps.reject { |app| app.new_app? }
    PassengerApplication.removeApplications(existing_apps) unless existing_apps.empty?
    @applicationsController.removeObjects apps
  end
  
  def rbSetValue_forKey(value, key)
    super
    browse if !@dropping_directories and key == 'applications' and !value.empty? and value.last.new_app?
  end
  
  def showPassengerHelp(sender)
    OSX::HelpHelper.openHelpPage File.expand_path('../English.lproj/PassengerPaneHelp/PassengerPaneHelp.html', __FILE__)
  end
  
  # Select application directory panel
  
  def browse(sender = nil)
    panel = NSOpenPanel.openPanel
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.objc_send(
      :beginSheetForDirectory, path_for_browser,
      :file, nil,
      :types, nil,
      :modalForWindow, mainView.window,
      :modalDelegate, self,
      :didEndSelector, 'openPanelDidEnd:returnCode:contextInfo:',
      :contextInfo, nil
    )
  end
  
  def openPanelDidEnd_returnCode_contextInfo(panel, button, contextInfo)
    app = @applicationsController.selectedObjects.first
    if button == OSX::NSOKButton
      app.setValue_forKey(panel.filename, 'path')
    else
      remove if app.new_app? and !app.dirty?
    end
  end
  
  # Applications NSTableView dataSource drag and drop methods
  
  def tableView_validateDrop_proposedRow_proposedDropOperation(tableView, info, row, operation)
    return OSX::NSDragOperationNone unless @authorized
    
    files = info.draggingPasteboard.propertyListForType(OSX::NSFilenamesPboardType)
    if files.all? { |f| File.directory? f }
      @applicationsTableView.setDropRow_dropOperation(@applicationsController.content.count, OSX::NSTableViewDropAbove)
      OSX::NSDragOperationGeneric
    else
      OSX::NSDragOperationNone
    end
  end
  
  def tableView_acceptDrop_row_dropOperation(tableView, info, row, operation)
    apps = info.draggingPasteboard.propertyListForType(OSX::NSFilenamesPboardType).map { |path| PassengerApplication.alloc.initWithPath(path) }
    @dropping_directories = true
    @applicationsController.addObjects apps
    @dropping_directories = false
  end
  
  def tableView_writeRowsWithIndexes_toPasteboard(tableView, rows, pboard)
    config_paths = @applicationsController.content.objectsAtIndexes(rows).map { |app| app.config_path }
    pboard.declareTypes_owner([OSX::NSFilenamesPboardType], self)
    pboard.setPropertyList_forType(config_paths, OSX::NSFilenamesPboardType)
    true
  end
  
  # SFAuthorizationView: TODO this should actualy move to the SecurityHelper, but for some reason in prototyping it didn't work, try again when everything is cleaned up.
  
  def authorizationViewDidAuthorize(authorizationView = nil)
    OSX::SecurityHelper.sharedInstance.authorizationRef = @authorizationView.authorization.authorizationRef
    self.authorized = true
  end
  
  def authorizationViewDidDeauthorize(authorizationView = nil)
    OSX::SecurityHelper.sharedInstance.deauthorize
    self.authorized = false
  end
  
  # When the pane wants to be unselected
  
  def shouldUnselect
    if @dirty_apps and !@applicationsController.content.empty?
      alert = OSX::NSAlert.alloc.init
      alert.messageText = 'This service has unsaved changes'
      alert.informativeText = 'Would you like to apply your changes before closing the Passenger preference pane?'
      alert.addButtonWithTitle 'Apply'
      alert.addButtonWithTitle 'Cancel'
      alert.addButtonWithTitle 'Don’t Apply'
      alert.objc_send(
        :beginSheetModalForWindow, mainView.window,
        :modalDelegate, self,
        :didEndSelector, 'unsavedChangesAlertDidEnd:returnCode:contextInfo:',
        :contextInfo, nil
      )
      return OSX::NSUnselectLater
    end
    OSX::NSUnselectNow
  end
  
  APPLY = OSX::NSAlertFirstButtonReturn
  CANCEL = OSX::NSAlertSecondButtonReturn
  DONT_APPLY = OSX::NSAlertThirdButtonReturn
  
  def unsavedChangesAlertDidEnd_returnCode_contextInfo(alert, returnCode, contextInfo)
    alert.window.orderOut(self)
    case returnCode
    when CANCEL
      replyToShouldUnselect false
      return
    when APPLY
      apply
    when DONT_APPLY
      @applicationsController.removeObjects @applicationsController.content.select { |app| app.new_app? }
      revert
    end
    replyToShouldUnselect true
  end
  
  private
  
  def authorize!
    result = @authorizationView.authorization.objc_send(
      :permitWithRight, OSX::KAuthorizationRightExecute,
      :flags, (OSX::KAuthorizationFlagPreAuthorize | OSX::KAuthorizationFlagExtendRights | OSX::KAuthorizationFlagInteractionAllowed)
    ) == 0
    authorizationViewDidAuthorize if result
    result
  end
  
  def setup_authorization_view!
    @authorized = false
    @authorizationView.string = OSX::KAuthorizationRightExecute
    @authorizationView.delegate = self
    @authorizationView.updateStatus self
    @authorizationView.autoupdate = true
  end
  
  def setup_applications_table_view!
    @applications = [].to_ns
    @applicationsTableView.dataSource = self
    @applicationsTableView.registerForDraggedTypes [OSX::NSFilenamesPboardType]
    @applicationsTableView.setDraggingSourceOperationMask_forLocal(OSX::NSDragOperationGeneric, false)
  end
  
  def load_appications!
    unless (existing_apps = PassengerApplication.existingApplications).empty?
      @applicationsController.addObjects existing_apps
      @applicationsController.selectedObjects = [existing_apps.last]
    end
  end
  
  def reload_appications!
    @applicationsController.content.each { |app| app.reload! }
  end
  
  def passenger_installed?
    `#{PassengerPaneConfig::HTTPD_BIN} -t -D DUMP_MODULES 2>&1`.include? 'passenger_module'
  end
  
  def path_for_browser
    app = @applicationsController.selectedObjects.first
    app.nil? ? OSX.NSHomeDirectory : app.path
  end
  
  MODRAILS_URL = 'http://www.modrails.com'
  def setup_passenger_warning!
    if passenger_installed?
      @installPassengerWarning.hidden = true
    else
      unless @setup_passenger_warning
        text_field = @installPassengerWarning.subviews.first
        
        link_str = OSX::NSMutableAttributedString.alloc.initWithString(MODRAILS_URL)
        range = OSX::NSMakeRange(0, MODRAILS_URL.length)
        link_str.addAttribute_value_range OSX::NSLinkAttributeName, MODRAILS_URL, range
        link_str.addAttribute_value_range OSX::NSForegroundColorAttributeName, OSX::NSColor.blueColor, range
        link_str.addAttribute_value_range OSX::NSUnderlineStyleAttributeName, OSX::NSSingleUnderlineStyle, range
        
        text_parts = text_field.stringValue.split(MODRAILS_URL)
        
        str = OSX::NSMutableAttributedString.alloc.initWithString(text_parts.first)
        str.appendAttributedString link_str
        str.appendAttributedString OSX::NSAttributedString.alloc.initWithString(text_parts.last)
        str.addAttribute_value_range OSX::NSFontAttributeName, OSX::NSFont.systemFontOfSize(11), OSX::NSMakeRange(0, str.length)
        
        text_field.attributedStringValue = str
        @setup_passenger_warning = true
      end
      
      @installPassengerWarning.hidden = false
    end
  end
end