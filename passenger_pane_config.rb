module PassengerPaneConfig
  APACHE_RESTART_COMMAND = "sudo /bin/launchctl stop org.apache.httpd"
  APACHE_DIR = "/private/etc/apache2"
  HTTPD_CONF = File.join(APACHE_DIR, 'httpd.conf')
  PASSENGER_APPS_DIR = File.join(APACHE_DIR, 'passenger_pane_vhosts')
end