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
  end
end