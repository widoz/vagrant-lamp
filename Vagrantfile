# -*- mode: ruby -*-
# vi: set ft=ruby :

# A set of Vagrant version requirements can be specified in the Vagrantfile to enforce
# that people use a specific version of Vagrant with a Vagrantfile.
# This can help with compatibility issues that may otherwise arise from using a too old or too new
# Vagrant version with a Vagrantfile.
# https://www.vagrantup.com/docs/vagrantfile/vagrant_version.html
Vagrant.require_version ">= 2.0.1"

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
#
# The most common configuration options are documented and commented below.
# For a complete reference, please see the online documentation at
# https://docs.vagrantup.com.
Vagrant.configure("2") do |config|
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/xenial64"

  # The version of the box to use. This defaults to ">= 0" (the latest version available).
  # This can contain an arbitrary list of constraints, separated by commas, such as: >= 1.0, < 1.5.
  # When constraints are given, Vagrant will use the latest available box satisfying these constraints.
  config.vm.box_version = ">= 20171221.0.0"

  # BootStrap
  config.vm.provision "shell" do |s|
      s.name = 'WordPress SushiCode'
      s.path = "inc/bootstrap.sh"
  end

  # Install PHP Switching
  config.vm.provision "shell" do |s|
      s.name = 'PHP Switching'
      s.path = "inc/phpswitching.sh"
  end

  # Memory
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", 2048]
  end

  # The hostname the machine should have. Defaults to nil. If nil, Vagrant will not manage the hostname.
  # If set to a string, the hostname will be set on boot.
  config.vm.hostname = 'wordpress.sushicode'

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  config.vm.box_check_update = false

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.10"

  # Set appropriate permissions to the site directories and files.
  # apache2 need user: www-data and owner: www-data
  config.vm.synced_folder ".", "/vagrant", owner: "www-data", group: "www-data", ["dmode=775,fmode=666"]

  config.vm.synced_folder "~/Me/Development/", "/srv/development",  owner: "www-data", group: "www-data", mount_options: ["dmode=775,fmode=666"]
end
