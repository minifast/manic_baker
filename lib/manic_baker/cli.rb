require "librarian/chef/cli"
require "thor"
require "thor/shell/mean"
require "fog"
require "manic_baker/config"
require "manic_baker/remote_config"
require "soloist/spotlight"
require "soloist/remote"

module ManicBaker
  class Cli < Thor
    include Thor::Shell::Mean

    desc "launch", "Launch a new instance, Alana"
    def launch(dataset = nil)
      unless dataset.nil?
        config.dataset = dataset
        config.save
      end

      check_dataset
      check_no_servers

      say_message_for(:start, :success, config.dataset)
      joyent.servers.create(config.to_hash)
      say_waiting_until { dataset_servers.first.state == "running" }
      say_message_for(:start, :success, dataset_servers.first.name)
    end

    desc "panic", "Destroy some instances or whatever?  Who cares."
    def panic
      check_dataset
      check_servers

      dataset_servers.each { |s| say_message_for(:stop, :success, s.name) }
      dataset_servers.each(&:destroy)
      say_waiting_until { !any_running? }
      say_message_for(:terminate, :success)
    end

    desc "ssh", "I'm just gonna take a moment okay?"
    def ssh
      check_dataset
      check_servers

      exec("ssh -i #{config.private_key_path} root@#{dataset_servers.first.public_ip_address}")
    end

    desc "bootstrap", "You know those boots are like 90s style right"
    def bootstrap
      check_dataset
      check_servers

      remote.upload("#{script_path}/", "script/")
      remote.system!("script/bootstrap.sh")
    end

    desc "chef", "Can you like make some spaghetti?  I'm so high."
    def chef
      check_dataset
      check_servers
      install_cookbooks if cheffile_exists?
      remote_config.run_chef
    end

    private

    def cheffile_exists?
      File.exists?(File.expand_path("../Cheffile", config_path))
    end

    def install_cookbooks
      Dir.chdir(File.dirname(config_path)) do
        Librarian::Chef::Cli.with_environment do
          Librarian::Chef::Cli.new.install
        end
      end
    end

    def any_running?
      dataset_servers.any? do |server|
        begin
          server.reload
          server.state == "running"
        rescue Excon::Errors::Gone
          false
        end
      end
    end

    def check_dataset
      if config.dataset.nil?
        raise Thor::Error.new("requires a dataset the first time out")
      end
    end

    def check_servers
      if dataset_servers.empty?
        raise Thor::Error.new("found zero servers with dataset #{config.dataset}")
      end
    end

    def check_no_servers
      unless dataset_servers.empty?
        raise Thor::Error.new("cannot clobber an existing instance")
      end
    end

    def script_path
      File.expand_path("../../../script", __FILE__)
    end

    def dataset_servers
      joyent.servers.reload.select do |server|
        server.dataset == config.dataset
      end
    end

    def say_waiting_until
      say_waiting
      say_until(".", nil, false) do
        yield.tap do |all_done|
          unless all_done
            say_boring if rand < 0.1
            sleep 1
          end
        end
      end
    end

    def remote_config
      @remote_config ||= ManicBaker::RemoteConfig.new(config, remote)
    end

    def remote
      @remote ||= Soloist::Remote.new(
        "root",
        dataset_servers.first.public_ip_address,
        config.private_key_path
      )
    end

    def joyent
      @joyent ||= Fog::Compute.new(
        provider: "Joyent",
        joyent_url: config.joyent_uri
      )
    end

    def config
      @config ||= ManicBaker::Config.from_file(config_path)
    end

    def config_path
      @config_path ||= Soloist::Spotlight.find!(".baker.yml")
    end
  end
end
