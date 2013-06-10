require "spec_helper"

describe ManicBaker::Cli do
  let(:config) { ManicBaker::Config.new }
  let(:config_hash) { config.to_hash }

  let(:dataset) { "some-image-or-other" }
  let(:server_dataset) { dataset }

  let(:fake_server) { double(:server, dataset: server_dataset) }
  let(:fake_server_collection) { [fake_server] }
  let(:fake_joyent) { double(:joyent, servers: fake_server_collection) }

  subject(:cli) { ManicBaker::Cli.new }

  before do
    fake_server.stub(reload: fake_server)
    fake_server_collection.stub(reload: fake_server_collection)
    cli.stub(config: config, joyent: fake_joyent, say: nil, say_status: nil)
  end

  describe "#launch" do
    let(:new_fake_server) { double(:server, dataset: dataset, name: "new", state: "running") }

    before do
      fake_server.stub(name: "some name")
      fake_server_collection.stub(:create) do
        fake_server_collection << new_fake_server
        new_fake_server
      end
    end

    context "with a dataset" do
      let(:config_hash) { config.to_hash.merge("dataset" => dataset) }

      context "when no instances exist with the dataset" do
        let(:server_dataset) { "i-am-another-data-set" }

        it "creates a new instance on joyent" do
          fake_server_collection.should_receive(:create).with(config_hash)
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
        let(:fake_server_collection) { [] }
        let(:dataset) { "fancy-dataset" }

        before { config.dataset = dataset }

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
    before do
      fake_server.stub(destroy: nil, name: "i hate this server anyway")
    end

    context "with a dataset in the config" do
      before { config.dataset = dataset }

      context "when there is a server with the dataset" do
        before { fake_server.stub(state: "stopped") }

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

      context "when the server has a different dataset" do
        let(:server_dataset) { "guess-who" }

        it "does not destroy the server" do
          expect { cli.panic }.to raise_error(Thor::Error)
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
    before do
      fake_server.stub(public_ip_address: "some-host")
      cli.stub(exec: nil)
    end

    context "with a dataset in the config" do
      before { config.dataset = dataset }

      context "when there is a server with the dataset" do
        it "starts an ssh session to the host" do
          cli.should_receive(:exec).with("ssh -i #{config.private_key_path} root@some-host")
          cli.ssh
        end
      end

      context "when the server has a different dataset" do
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

  describe "#bootstrap" do
    let(:fake_remote) { double(:remote, system!: nil, upload: nil) }

    before { cli.stub(remote: fake_remote) }

    context "with a dataset in the config" do
      let(:script_path) { File.expand_path("../../../../script", __FILE__) }

      before { config.dataset = dataset }

      context "when the server is in the same dataset" do
        it "uploads the script directory" do
          fake_remote.should_receive(:upload).with("#{script_path}/", "script/")
          cli.bootstrap
        end

        it "runs the bootstrap script" do
          fake_remote.should_receive(:system!).with("script/bootstrap.sh")
          cli.bootstrap
        end
      end

      context "when the server has a different dataset" do
        let(:server_dataset) { "i-am-so-tired-of-guessing" }

        it "does not destroy the server" do
          expect { cli.bootstrap }.to raise_error(Thor::Error)
        end
      end
    end

    context "with no dataset in the config" do
      before { config.dataset = nil }

      it "raises an exception" do
        expect { cli.bootstrap }.to raise_error(Thor::Error)
      end
    end
  end

  describe "#chef" do
    let(:fake_remote_config) { double(:remote_config) }

    before { cli.stub(remote_config: fake_remote_config, install_cookbooks: nil) }

    context "with a dataset in the config" do
      before { config.dataset = dataset }

      context "when there is a server with the dataset" do
        it "starts an ssh session to the host" do
          fake_remote_config.should_receive(:run_chef)
          cli.chef
        end
      end

      context "when the server has a different dataset" do
        let(:server_dataset) { "wait, there's more than one of these?" }

        it "does not destroy the server" do
          expect { cli.chef }.to raise_error(Thor::Error)
        end
      end
    end

    context "with no dataset in the config" do
      before { config.dataset = nil }

      it "raises an exception" do
        expect { cli.chef }.to raise_error(Thor::Error)
      end
    end
  end
end
