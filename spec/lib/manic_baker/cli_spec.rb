require "spec_helper"

describe ManicBaker::Cli do
  let(:config) { ManicBaker::Config.new }
  let(:config_hash) { config.to_hash }

  subject(:cli) { ManicBaker::Cli.new }

  before { cli.stub(config: config, say_status: nil) }

  describe "#launch" do
    let(:fake_servers) { double(:servers, bootstrap: nil) }
    let(:fake_joyent) { double(:joyent, servers: fake_servers) }

    before { cli.stub(joyent: fake_joyent) }

    context "with a dataset" do
      let(:dataset) { "some-image-or-other" }

      it "bootstraps a new instance on joyent" do
        fake_servers.should_receive(:bootstrap).with(config_hash.merge("dataset" => dataset))
        cli.launch(dataset)
      end

      it "writes the dataset to the config file" do
        expect do
          cli.launch(dataset)
        end.to change { config.dataset }.from(nil).to(dataset)
      end
    end

    context "without a dataset" do
      context "when the config has a dataset" do
        before { config.dataset = "fancy-dataset" }

        it "does not change the dataset in the config file" do
          expect { cli.launch }.to_not change { config.dataset }
        end
      end

      context "when the config does not have a dataset" do
        it "raises an error" do
          expect { cli.launch }.to raise_error(Thor::Error)
        end
      end
    end
  end
end
