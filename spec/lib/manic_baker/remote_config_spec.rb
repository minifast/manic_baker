require "spec_helper"

describe ManicBaker::RemoteConfig do
  let(:contents) { {} }
  let(:tempfile) do
    Tempfile.new("manic-baker-config").tap do |file|
      file.write(YAML.dump(contents))
      file.close
    end
  end
  let(:config) { ManicBaker::Config.new(:path => tempfile.path) }
  let(:remote) { Soloist::Remote.new("user", "host", "key") }
  let(:remote_config) { ManicBaker::RemoteConfig.new(config, remote) }

  before { remote.stub(:backtick => "", :system => 0) }

  def commands_for(method)
    [].tap do |commands|
      remote.stub(:system) { |c| commands << c; 0 }
      remote.stub(:backtick) { |c| commands << c; "" }
      remote_config.send(method)
    end
  end

  describe "#chef_config_path" do
    it "sets the path" do
      remote_config.chef_config_path.should == "/etc/chef"
    end

    it "creates the path remotely" do
      commands_for(:chef_config_path).tap do |commands|
        commands.should have(1).command
        commands.first.should =~ /mkdir .*? -p \/etc\/chef$/
      end
    end
  end

  describe "#chef_cache_path" do
    it "sets the path" do
      remote_config.chef_cache_path.should == "/var/chef/cache"
    end

    it "creates the path remotely" do
      commands_for(:chef_cache_path).tap do |commands|
        commands.should have(1).command
        commands.first.should =~ /mkdir .*? -p \/var\/chef\/cache$/
      end
    end
  end

  describe "#cookbook_paths" do
    it "sets the path" do
      remote_config.cookbook_paths.should have(1).path
      remote_config.cookbook_paths.should =~ ["/var/chef/cookbooks"]
    end

    it "creates the path remotely" do
      commands_for(:cookbook_paths).tap do |commands|
        commands.should have(1).command
        commands.first.should =~ /mkdir .*? -p \/var\/chef\/cookbooks$/
      end
    end
  end
end
