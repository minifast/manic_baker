require "spec_helper"

describe ManicBaker::Cli do
  let(:config) { ManicBaker::Config.new }
  let(:config_hash) { config.to_hash }

  subject(:cli) { ManicBaker::Cli.new }

  before { cli.stub(config: config, say: nil, say_status: nil) }

  describe "#launch" do
    let(:fake_server) { double(:server, reload: nil, state: "running", name: "hi") }
    let(:fake_servers) { double(:servers, create: fake_server) }
    let(:fake_joyent) { double(:joyent, servers: fake_servers) }

    before { cli.stub(joyent: fake_joyent) }

    context "with a dataset" do
      let(:dataset) { "some-image-or-other" }

      it "creates a new instance on joyent" do
        fake_servers.should_receive(:create).with(config_hash.merge("dataset" => dataset))
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

  describe "#panic" do
    let(:dataset) { "chicken-butt" }
    let(:server_dataset) { dataset }
    let(:fake_server) { double(:server, dataset: server_dataset, name: "uh") }
    let(:fake_joyent) { double(:joyent, servers: [fake_server]) }

    before { cli.stub(joyent: fake_joyent) }

    context "with a dataset in the config" do
      before { config.dataset = dataset }

      context "when there is a server with the dataset" do
        it "destroys the server" do
          fake_server.should_receive(:destroy)
          cli.panic
        end
      end

      context "when there the server has a different dataset" do
        let(:server_dataset) { "guess-who" }

        it "does not destroy the server" do
          fake_server.should_not_receive(:destroy)
          cli.panic
        end
      end
    end

    context "with no dataset in the config" do
      before { config.dataset = nil }

      it "raises an exception" do
        expect { cli.panic }.to raise_error(Thor::Error)
      end
    end
  end
end
