$KCODE = 'u'

Gem::Specification.new do |spec|
  spec.name    = "ppane"
  spec.version = "0.1.0"
  
  spec.authors = ["Eloy Duran",      "Manfred Stienstra"]
  spec.email   = ["eloy@fngtps.com", "manfred@fngtps.com"]
  
  spec.summary = <<-EOF
    Configuration tool for applications running on Phusion Passenger™.
  EOF
  
  spec.description = <<-EOF
    The Passenger Pane is a preference pane on Mac OS X. Ppane is the backend tool
    that does all the heavy lifting. It manages virtual hosts in your Apache configuration
    as well as hostname registration with Domain Services.
  EOF
  
  spec.files            = Dir["lib/**/*.rb"] + %w(LICENSE)
  spec.executables      = ["ppane"]
  spec.has_rdoc         = true
  spec.extra_rdoc_files = ["LICENSE"]
  spec.rdoc_options    << "--charset=utf-8"
end