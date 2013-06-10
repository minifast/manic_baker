class Thor
  module Shell
    module Mean
      def messages
        path = File.expand_path("../../../../config/locales/en.yml", __FILE__)
        @messages ||= YAML.load_file(path)
      end

      def message_for(topic, state, *parameters)
        messages[state.to_s][topic.to_s].sample % parameters
      end

      def say_message_for(topic, state, *parameters)
        say_status(topic, message_for(topic, state, *parameters))
      end

      def say_until(*args)
        say(*args) until yield
        say
      end

      def say_waiting
        status = set_color("waiting".rjust(12), :green, true)
        say("#{status}  ", nil, false)
      end

      def say_boring
        puts
        say_status(nil, messages["boring"].sample)
        say_waiting
      end
    end
  end
end
