class OptionParser
  def self.parse(argv)
    return [{},[]] if argv.empty?
    
    options  = {}
    rest     = []
    switch   = nil
    
    for value in argv
      # values is a switch
      if value[0] == 45
        switch = value.slice((value[1] == 45 ? 2 : 1)..-1)
        options[switch] = nil
      else
        if switch
          # we encountered a switch so this
          # value belongs  to  that  switch
          options[switch] = value
          switch = nil
        else
          rest << value
        end
      end
    end
    
    [options, rest]
  end
end