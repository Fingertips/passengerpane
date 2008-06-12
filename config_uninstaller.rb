#!/usr/bin/env ruby

require 'fileutils'
require File.expand_path('../file_backup_and_open', __FILE__)

vhost_file, hosts_file, host = ARGV

FileUtils.rm vhost_file
File.backup_and_remove_data(hosts_file, "\n127.0.0.1\t\t\t#{host}")