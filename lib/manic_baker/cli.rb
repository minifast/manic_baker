require "thor"
require "fog"
require "manic_baker/config"
require "soloist/spotlight"

module ManicBaker
  class Cli < Thor
    desc "launch", "Launch a new instance"
    method_option :identity, :aliases => "-i", :desc => "The SSH identity file"
    def launch(dataset = nil)
      say_success_for :start, dataset
      config.dataset = dataset unless dataset.nil?
      raise Thor::Error.new(failure_for(:start, "some dataset that was nil")) if config.dataset.nil?
      joyent.servers.bootstrap(config.to_hash)
    end

    private

    def joyent
      @joyent ||= Fog::Compute.new(:provider => "Joyent")
    end

    def config
      @config ||= ManicBaker::Config.new(config_path)
    end

    def config_path
      @config_path ||= Soloist::Spotlight.find!(".baker.yml")
    end

    def say_success_for(stage, subject)
      say_status(stage, success_for(stage, subject))
    end

    def success_for(stage, subject)
      messages["success"][stage.to_s].sample % subject
    end

    def failure_for(stage, subject)
      messages["failure"][stage.to_s].sample % subject
    end

    def messages
      @messages ||= YAML.load_file(messages_path)["cli"]
    end

    def messages_path
      File.expand_path("../../../config/locales/en.yml", __FILE__)
    end
  end
end
