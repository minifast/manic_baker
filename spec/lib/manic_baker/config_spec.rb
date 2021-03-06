require "spec_helper"

describe ManicBaker::Config do
  let(:contents) { { "recipes" => ["broken_vim"] } }
  let(:tempfile) do
    Tempfile.new("manic-baker-config").tap do |file|
      file.write(YAML.dump(contents))
      file.close
    end
  end

  let(:royal_crown) { ManicBaker::Config.from_file(tempfile.path) }

  describe "defaults" do
    its(:dataset) { should be_nil }
    its(:flavor) { should == "Small 1GB" }
    its(:joyent_uri) { should == "https://us-east-1.api.joyentcloud.com" }
    its(:private_key_path) { should == File.expand_path("~/.ssh/id_rsa") }
    its(:public_key_path) { should == File.expand_path("~/.ssh/id_rsa.pub") }
  end

  describe ".from_file" do
    context "when the rc file is empty" do
      let(:tempfile) do
        Tempfile.new("manic-baker-config").tap do |file|
          file.close
        end
      end

      it "loads an empty file" do
        expect { royal_crown }.not_to raise_error
      end
    end

    it "loads from a yaml file" do
      royal_crown.recipes.should =~ ["broken_vim"]
    end

    it "defaults nil fields to an empty primitive" do
      royal_crown.node_attributes.should == {}
    end

    context "when the rc file has ERB tags" do
      let(:tempfile) do
        Tempfile.new("manic-baker-config").tap do |file|
          file.write(<<-YAML
          recipes:
            - broken_vim
          node_attributes:
            evaluated: <%= "From ERB" %>
          YAML
          )
          file.close
        end
      end

      it "evaluates the ERB and parses the resulting YAML" do
        royal_crown.node_attributes.should == {
          "evaluated" => "From ERB"
        }
        royal_crown.recipes.should =~ ["broken_vim"]
      end
    end
  end

  describe "#save" do
    it "writes the values to a file" do
      royal_crown.recipes = ["hot_rats", "tissue_paper"]
      royal_crown.save
      royal_crown = ManicBaker::Config.from_file(tempfile.path)
      royal_crown.recipes.should =~ ["hot_rats", "tissue_paper"]
    end
  end

  describe "#to_yaml" do
    it "skips the path attribute" do
      royal_crown.to_yaml.keys.should_not include "path"
    end

    it "nils out fields that have not been set" do
      royal_crown.to_yaml["node_attributes"].should be_nil
    end
  end
end
