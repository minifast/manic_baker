require "spec_helper"

describe ManicBaker::Cli do
  let(:config) { ManicBaker::Config.new }
  let(:config_hash) { config.to_hash }

  subject(:cli) { ManicBaker::Cli.new }

  before { cli.stub(config: config, say: nil, say_status: nil) }

  describe "#launch" do
    let(:dataset) { "some-image-or-other" }
    let(:server_dataset) { dataset }
    let(:fake_server) { double(:server, reload: nil, state: "running", name: "hi", dataset: server_dataset) }
    let(:fake_server_collection) { [fake_server] }
    let(:fake_joyent) { double(:joyent, servers: fake_server_collection) }

    before do
      fake_server.stub(reload: fake_server)
      fake_server_collection.stub(
        create: fake_server,
        reload: fake_server_collection
      )
      cli.stub(joyent: fake_joyent)
    end

    context "with a dataset" do
      let(:config_hash) { config.to_hash.merge("dataset" => dataset) }

      context "when no instances exist with the dataset" do
        let(:server_dataset) { "i-am-another-data-set" }

        it "creates a new instance on joyent" do
          fake_server_collection.should_receive(:create).with(config_hash).and_return(fake_server)
          cli.launch(dataset)
        end

        it "writes the dataset to the config file" do
          expect do
            cli.launch(dataset)
          end.to change { config.dataset }.from(nil).to(dataset)
        end
      end

      context "when an instance exists with the dataset" do
        it "raises an error" do
          expect { cli.launch(dataset) }.to raise_error(Thor::Error)
        end
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
    let(:fake_server) { double(:server, dataset: server_dataset, name: "uh", state: "pizza") }
    let(:fake_server_collection) { [fake_server] }
    let(:fake_joyent) { double(:joyent, servers: fake_server_collection) }

    before do
      fake_server.stub(reload: fake_server, destroy: nil)
      fake_server_collection.stub(reload: fake_server_collection)
      cli.stub(joyent: fake_joyent)
    end

    context "with a dataset in the config" do
      before { config.dataset = dataset }

      context "when there is a server with the dataset" do
        it "destroys the server" do
          fake_server.should_receive(:destroy)
          cli.panic
        end

        context "when reloading the server raises 410 Gone" do
          it "does not raise an error" do
            fake_server.stub(:reload).and_raise(Excon::Errors::Gone.new("no"))
            expect { cli.panic }.to_not raise_error
          end
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

  describe "#ssh" do
    let(:dataset) { "chicken-butt" }
    let(:server_dataset) { dataset }
    let(:fake_server) { double(:server, dataset: server_dataset, public_ip_address: "some-host") }
    let(:fake_joyent) { double(:joyent, servers: [fake_server]) }

    before { cli.stub(joyent: fake_joyent, exec: nil) }

    context "with a dataset in the config" do
      before { config.dataset = dataset }

      context "when there is a server with the dataset" do
        it "starts an ssh session to the host" do
          cli.should_receive(:exec).with("ssh -i #{config.private_key_path} root@some-host")
          cli.ssh
        end
      end

      context "when there the server has a different dataset" do
        let(:server_dataset) { "guess-who" }

        it "does not destroy the server" do
          expect { cli.ssh }.to raise_error(Thor::Error)
        end
      end
    end

    context "with no dataset in the config" do
      before { config.dataset = nil }

      it "raises an exception" do
        expect { cli.ssh }.to raise_error(Thor::Error)
      end
    end
  end
end
