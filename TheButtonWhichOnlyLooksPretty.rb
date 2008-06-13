require 'osx/cocoa'
include OSX

class TheButtonWhichOnlyLooksPretty < NSButton
  def mouseDown(event)
    # Haha. Forget about it!
  end
end