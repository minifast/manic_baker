require "soloist/royal_crown"

module ManicBaker
  class Config < Soloist::RoyalCrown
    property :dataset
    property :joyent_uri, :default => "https://us-east-1.api.joyentcloud.com"
    property :flavor, :default => "Small 1GB"
    property :ssh_key_name, :default => "id_rsa"
    property :private_key_path, :default => File.expand_path("~/.ssh/id_rsa")

    def public_key_path
      "#{self.private_key_path}.pub"
    end

    private

    def self.nilable_properties
      (properties - [:path, :dataset]).map(&:to_s)
    end
  end
end
