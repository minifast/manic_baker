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
      config.dataset = dataset unless dataset.nil?

      if config.dataset.nil?
        say_message_for :start, :failure, "some dataset that was nil"
        raise Thor::Error.new("launch requires a dataset the first time out")
      end

      config.save
      say_message_for :start, :success, config.dataset

      server = joyent.servers.create(config.to_hash)
      wait_for_server_state(server, "running")

      say_message_for :start, :success, server.name
      server
    end

    desc "panic", "Destroy some instances or whatever?  Who cares."
    def panic
      if config.dataset.nil?
        say_message_for :terminate, :failure, "some dataset that was nil"
        raise Thor::Error.new("panic requires a dataset the first time out")
      end

      servers = joyent.servers.select { |s| s.dataset == config.dataset }
      unless servers.empty?
        servers.each do |server|
          say_message_for :stop, :success, server.name
          server.destroy
        end

        say_message_for :terminate, :success
      end
    end

    private

    def wait_for_server_state(server, state)
      say_waiting
      say_until(".", nil, false) do
        server.reload
        (server.state == state).tap do |is_running|
          unless is_running
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
