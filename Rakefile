namespace :ec2 do
  CHEF_ROOT = File.dirname(__FILE__)

  task :load_config do
    require "EC2"

    @config = YAML::load(File.open(File.join(File.dirname(__FILE__), "config/ec2.yml")))
    @config.symbolize_keys!

    @ec2 = EC2::Base.new(@config)
  end

  desc "Boot EC2 instances defined in RAILS_ROOT/config/ec2.yml"
  task :boot => :load_config do
    puts "Booting instances..."

    @ec2.run_instances(@config.merge(:user_data => user_data, :base64_encoded => true))

    puts "\n"

    Rake::Task["ec2:status"].invoke
  end

  desc "Print status of all EC2 instances owned by the user defined in RAILS_ROOT/config/ec2.yml"
  task :status => :load_config do
    table = [["Instance ID", "AMI ID", "Type", "Status", "Public DNS", "Key Pair"]]

    instances.each do |instance|
      table << [instance.instanceId, instance.imageId, instance.instanceType, instance.instanceState.name, instance.dnsName, instance.keyName]
    end

    puts table.tabularize
  end

  desc "Configure EC2 instances using Chef cookbooks defined in RAILS_ROOT/config/chef"
  task :configure => :load_config do
    puts "Configuring instances..."

    instances.each do |instance|
      if instance.instanceState.name == "running"
        sh "rsync -qrlP --delete #{CHEF_ROOT}/ root@#{instance.dnsName}:/etc/chef"
        sh "ssh -A root@#{instance.dnsName} \"chef-solo -c /etc/chef/config/solo.rb -j /etc/chef/config/dna.json\""
      end
    end
  end

  desc "Terminate all EC2 instances owned by the user defined in RAILS_ROOT/config/ec2.yml"
  task :terminate => :load_config do
    puts "Terminating instances..."

    instances.each do |instance|
      @ec2.terminate_instances(:instance_id => instance.instanceId)
    end

    puts "\n"

    Rake::Task["ec2:status"].invoke
  end

private

  def user_data
<<-EOD
#!/bin/bash
apt-get -y update
apt-get -y install build-essential irb ri rdoc ruby1.8-dev wget

# RubyGems
cd /tmp
wget http://rubyforge.org/frs/download.php/56227/rubygems-1.3.3.tgz
tar zxvf rubygems-1.3.3.tgz
cd rubygems-1.3.3
sudo ruby setup.rb
sudo ln -sfv /usr/bin/gem1.8 /usr/bin/gem

# Chef
gem install chef ohai --no-ri --no-rdoc --source http://gems.opscode.com --source http://gems.rubyforge.org
mkdir /etc/chef
EOD
  end

  def instances
    if reservations = @ec2.describe_instances.reservationSet
      reservations.item.collect { |reservation| reservation.instancesSet.item }.flatten
    else
      []
    end
  end

  class Array
    def tabularize
      format = "|"

      self.first.each_index do |index|
        column_width = self.collect { |row| row[index].to_s.length }.max
        format << " %-#{column_width}s |"
      end

      self.collect do |row|
        format % row
      end
    end
  end

  class Hash
    def symbolize_keys!
      each do |k,v|
        sym = k.respond_to?(:to_sym) ? k.to_sym : k
        self[sym] = Hash === v ? v.symbolize_keys! : v
        delete(k) unless k == sym
      end

      self
    end
  end
end