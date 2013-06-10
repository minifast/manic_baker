$:<<File.expand_path("../../lib", __FILE__)

require "manic_baker"

Dir.glob(File.expand_path("../support/**/*.rb", __FILE__)) { |f| require f }

RSpec.configure do |config|
  config.include CaptureStreamHelpers
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
