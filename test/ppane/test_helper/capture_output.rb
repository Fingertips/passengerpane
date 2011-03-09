module TestHelper
  module CaptureOutput
    def capture_stdout(&block)
      collector = Collector.new
      stdout = $stdout
      $stdout = collector
      begin
        block.call
      ensure
        $stdout = stdout
      end
      collector.written.join
    end
    
    def capture_stderr(&block)
      collector = Collector.new
      stderr = $stderr
      $stderr = collector
      begin
        block.call
      ensure
        $stderr = stderr
      end
      collector.written.join
    end
  end
end