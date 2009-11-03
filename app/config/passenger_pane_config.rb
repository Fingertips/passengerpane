module PassengerPaneConfig
  RUBY = "/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby"
  HTTPD_BIN = "/usr/sbin/httpd"
  APACHE_RESTART_COMMAND = "/sbin/service org.apache.httpd stop; /sbin/service org.apache.httpd start"
  APACHE_DIR = "/private/etc/apache2"
  HTTPD_CONF = File.join(APACHE_DIR, 'httpd.conf')
  PASSENGER_APPS_DIR = File.join(APACHE_DIR, 'passenger_pane_vhosts')
  PASSENGER_APPS_EXTENSION = "vhost.conf"
end