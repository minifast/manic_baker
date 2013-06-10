require "thor"
require "thor/shell/mean"
require "fog"
require "manic_baker/config"
require "soloist/spotlight"

module ManicBaker
  class Cli < Thor
    include Thor::Shell::Mean

    desc "launch", "Launch a new instance, Alana"
    def launch(dataset = nil)
      unless dataset.nil?
        config.dataset = dataset
        config.save
      end

      if config.dataset.nil?
        say_message_for :start, :failure, "some dataset that was nil"
        raise Thor::Error.new("launch requires a dataset the first time out")
      end

      unless dataset_servers.empty?
        say_message_for :start, :failure, dataset_servers
        raise Thor::Error.new("launch cannot clobber an existing instance")
      end

      say_message_for :start, :success, config.dataset

      server = joyent.servers.create(config.to_hash)
      say_waiting_until do
        server.reload
        server.state == "running"
      end

      say_message_for :start, :success, server.name
      server
    end

    desc "panic", "Destroy some instances or whatever?  Who cares."
    def panic
      if config.dataset.nil?
        say_message_for :terminate, :failure, "some dataset that was nil"
        raise Thor::Error.new("panic requires a dataset the first time out")
      end

      unless dataset_servers.empty?
        dataset_servers.each do |server|
          say_message_for :stop, :success, server.name
          server.destroy
        end

        say_waiting_until do
          dataset_servers.empty? || dataset_servers.all? do |server|
            begin
              server.reload
              server.state != "running"
            rescue Excon::Errors::Gone
              true
            end
          end
        end

        say_message_for :terminate, :success
      end
    end

    desc "ssh", "I'm just gonna take a moment okay?"
    def ssh
      if config.dataset.nil?
        say_message_for :terminate, :failure, "some dataset that was nil"
        raise Thor::Error.new("ssh requires a dataset the first time out")
      end

      server = joyent.servers.detect { |s| s.dataset == config.dataset }

      if server.nil?
        say_message_for :ssh, :failure, config.dataset
        raise Thor::Error.new("found zero servers with dataset #{config.dataset}")
      end

      exec("ssh -i #{config.private_key_path} root@#{server.public_ip_address}")
    end

    private

    def dataset_servers
      joyent.servers.reload.select { |s| s.dataset == config.dataset }
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

    def joyent
      @joyent ||= Fog::Compute.new(
        :provider => "Joyent",
        :joyent_url => config.joyent_uri
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
