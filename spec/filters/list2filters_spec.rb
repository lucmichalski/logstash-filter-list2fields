# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/event"
require "logstash/filters/list2fields"

describe LogStash::Filters::List2fields do

  # Test cases: 1     [ { "key" => "animal", "value" => "horse"} , {"key" => "food", "value" => "bacon"} ]          list of hashes with splitted fields for key and value
  # Test cases: 2     [ { "animal" => "horse"} , {"food" => "bacon"} ]                                              list of hashes with k => v structure

  context "without prefix" do

    let(:plugin) { LogStash::Filters::List2fields.new("source" => "message") }

    before do
      plugin.register
    end

    context "when the source field is empty" do

      let(:event) { LogStash::Event.new() }
      it "should not throw an exception" do
        expect {
          plugin.filter(event)
        }.not_to raise_error
      end # it
    end # context

    context "when the source field is not iterable" do

      let(:event) { LogStash::Event.new("message" => "i_am_not_iterable" ) }
      it "should not throw an exception" do
        expect {
          plugin.filter(event)
        }.not_to raise_error
      end # it
    end # context

    context "when remove_source is set to true" do

      let(:event) { LogStash::Event.new("message" => [{"key"=>"foo","value"=>"bar"}]) }
      before do
        plugin.filter(event)
      end

      it "should remove the input field" do
        expect(event.get("message")).to be_nil
      end # it
    end # context

    context "when remove_source is set to false" do

      let(:event) { LogStash::Event.new("message" => [{"key"=>"foo","value"=>"bar"}]) }
      let(:plugin) { LogStash::Filters::List2fields.new("source" => "message", "remove_source" => false) }

      before do
        plugin.register
        plugin.filter(event)
      end

      it "should not remove the input field" do
        expect(event.get("message")).not_to be_empty
      end # it
    end # context


    context "operates on a list of hashes with splitted key and value entries (using names) (testcase 1)" do
      let(:event) { LogStash::Event.new("cheese" => "chili", "message" => [{"key"=>"foo","value"=>"bar"},{"key"=>"cheese","value"=>"gorgonzola"}]) }
      let(:plugin) { LogStash::Filters::List2fields.new("source" => "message", "key" => "key", "value" => "value") }
      before do
        plugin.register
        plugin.filter(event)
      end

      it "should have new fields" do
        expect(event.get("foo")).to eq("bar")
        expect(event.get("cheese")).to eq("gorgonzola")
      end # it
    end # context


    context "operates on a list of hashes with key and value in one tuple (testcase 2)." do
      let(:event) { LogStash::Event.new("cheese" => "chili", "message" => [{"foo"=>"bar"},{"cheese"=>"gorgonzola"}]) }
      before do
        plugin.register
        plugin.filter(event)
      end

      it "should have new fields" do
        expect(event.get("foo")).to eq("bar")
        expect(event.get("cheese")).to eq("gorgonzola")
      end # it
    end # context

  end # context no prefix set

  context "with prefix " do

    context "operates on a list of hashes with splitted key and value entries (using names) (testcase 1)" do
      let(:plugin) { LogStash::Filters::List2fields.new("source" => "message", "prefix" => "l2f_", "key" => "key", "value" => "value") }
      let(:event) { LogStash::Event.new("cheese" => "chili", "message" => [{"key"=>"foo","value"=>"bar"},{"key"=>"cheese","value"=>"gorgonzola"}]) }
      before do
        plugin.register
        plugin.filter(event)
      end

      it "should have new fields with the prefix in the key" do
        expect(event.get("l2f_foo")).to eq("bar")
        expect(event.get("l2f_cheese")).to eq("gorgonzola")
      end # it

      it "should not overwrite existing fields" do
        expect(event.get("cheese")).to eq("chili")
      end # it
    end # context



    context "operates on a list of hashes with key and value in one tuple (testcase 2)." do
      let(:plugin) { LogStash::Filters::List2fields.new("source" => "message", "prefix" => "l2f_") }
      let(:event) { LogStash::Event.new("cheese" => "chili", "message" => [{"foo"=>"bar"},{"cheese"=>"gorgonzola"}]) }
      before do
        plugin.register
        plugin.filter(event)
      end

      it "should have new fields with the prefix in the key" do
        expect(event.get("l2f_foo")).to eq("bar")
        expect(event.get("l2f_cheese")).to eq("gorgonzola")
      end # it
    end # context

  end # context prefix set


   context "not a list" do
    let(:plugin) { LogStash::Filters::List2fields.new("source" => "nomad") }
    let(:event) { LogStash::Event.new("foo" => 13, "bar" => 14, "nomad" =>
        {
        "namespace"=> "default",
        "datacenters"=> ["eu","us"],
        "task"=> {
          "name"=> "random_string",
          "service"=> {
            "name"=> "demo",
            "tags"=> ["a","b","c"],
            "empty_tags"=> []
            }
          }
        })}
      before do
        plugin.register
        plugin.filter(event)
      end

      it "should have moved the array entries into fields" do
        expect(event.get("foo")).to eq(13)
        expect(event.get("bar")).to eq(14)
        expect(event.get("namespace")).to eq("default")
        expect(event.get("task")["name"]).to eq("random_string")
        expect(event.get("task")["service"]["name"]).to eq("demo")
        expect(event.get("task")["service"]["tags"]).to eq(["a","b","c"])
        expect(event.get("task")["service"]["empty_tags"]).to eq([])
        # TODO finish
      end # it
  end # context


end # describe

