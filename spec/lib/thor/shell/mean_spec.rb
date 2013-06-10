require "spec_helper"

describe Thor::Shell::Mean do
  let(:contents) { { "failure" => { "binge_drinking" => ["your %s is over"] } } }

  class MeanHarness
    include Thor::Shell::Mean

    def say(string, _ = nil, newline = true)
      newline ? puts(string) : print(string)
    end
    def say_status(*args)
      say(args)
    end
    def set_color(string, *args)
      string
    end
  end

  subject(:mean) { MeanHarness.new }

  before { mean.stub(messages: contents) }

  describe "attributes" do
    context "when the messages path has been set" do
      its(:messages) { should have_key("failure") }
      its(:'messages.values.first') { should have_key("binge_drinking") }
    end
  end

  describe "#message_for" do
    let(:parameters) { ["life"] }
    let(:topic) { :binge_drinking }
    let(:state) { :failure }

    context "when the topic exists" do
      context "when the state exists" do
        specify { mean.message_for(topic, state, *parameters).should == "your life is over" }
      end

      context "when the state does not exist" do
        let(:state) { :success }

        specify { expect { mean.message_for(topic, state, *parameters) }.to raise_error(NoMethodError) }
      end
    end

    context "when the topic does not exist" do
      let(:topic) { :empathy }

      specify { expect { mean.message_for(topic, state, *parameters) }.to raise_error(NoMethodError) }
    end

    context "when there are not enough parameters" do
      specify { expect { mean.message_for(topic, state) }.to raise_error(ArgumentError) }
    end
  end

  describe "#say_message_for" do
    let(:output) do
      capture(:stdout) do
        mean.say_message_for(:binge_drinking, :failure, "relationship")
      end
    end

    specify { output.should include "binge_drinking" }
    specify { output.should include "your relationship is over" }
  end

  describe "#say_until" do
    context "with a state that is always true" do
      it "does not pass arguments to say" do
        mean.should_not_receive(:say).with(:anything)
        mean.should_receive(:say).with(no_args)
        mean.say_until(:anything) { true }
      end
    end

    context "with a state that transitions from false to true" do
      it "passes arguments to say" do
        mean.should_receive(:say).once.with(:anything)
        mean.should_receive(:say).with(no_args)
        index = 0
        mean.say_until(:anything) { (index += 1) == 2 }
      end
    end
  end

  describe "#say_waiting" do
    let(:output) { capture(:stdout) { mean.say_waiting } }

    specify { output.should include "waiting" }
    specify { output.should_not include "\n" }
  end

  describe "#say_boring" do
    let(:contents) { { "boring" => ["ugh"] } }
    let(:output) { capture(:stdout) { mean.say_boring } }

    specify { output.should include "ugh" }
    specify { output.should include "waiting" }
  end
end
