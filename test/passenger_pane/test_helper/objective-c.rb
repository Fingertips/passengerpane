require 'fileutils'

module ObjectiveC
  class CompileError < ::StandardError; end
  
  class << self
    def require(path, *frameworks)
      compile path, *frameworks
      Kernel.require bundle_path(path)
    end
    
    private
    
    def klass(path)
      File.basename(path)
    end
    
    def root_path
      File.expand_path('../../../../', __FILE__)
    end
    
    def output_dir
      File.join(root_path, 'test', 'tmp', 'build', 'bundles')
    end
    
    def ensure_output_dir!
      FileUtils.mkdir_p(output_dir) unless File.exist?(output_dir)
    end
    
    def header_file(path)
      File.join(root_path, "#{path}.h")
    end
    
    def implementation_file(path)
      File.join(root_path, "#{path}.m")
    end
    
    def source_file(path)
      File.join(output_dir, "#{klass(path)}.m")
    end
    
    def bundle_path(path)
      File.join(output_dir, "#{klass(path)}.bundle")
    end
    
    def prepare_source_file(path)
      FileUtils.cp(implementation_file(path), output_dir)
      FileUtils.cp(header_file(path), output_dir) if File.exist?(header_file(path))
      File.open(source_file(path), 'a') do |file|
        file.write("\n\nvoid Init_#{klass(path)}() {}")
      end
    end
    
    def compile(path, *frameworks)
      ensure_output_dir!
      prepare_source_file(path)
      source_path = source_file(path)
      frameworks.unshift 'Foundation'
      command = "gcc -o #{bundle_path(path)} -fobjc-gc -flat_namespace -undefined suppress -bundle #{frameworks.map { |f| "-framework #{f}" }.join(' ')} -I#{File.dirname(source_path)} #{source_path}"
      unless system(command)
        raise CompileError, "Unable to compile class `#{klass(path)}' at path: `#{source_path}'."
      end
    end
  end
end