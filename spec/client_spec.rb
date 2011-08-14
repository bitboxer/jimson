require 'spec_helper'

module Jimson
  describe Client do
    BOILERPLATE = {'jsonrpc' => '2.0', 'id' => 1}

    before(:each) do
      @resp_mock = mock('http_response')
      ClientHelper.stub!(:make_id).and_return(1)
    end

    after(:each) do
    end

    describe "#[]" do
      before(:each) do
        expected = {
                     'jsonrpc' => '2.0',
                     'method'  => 'foo',
                     'params'  => [1,2,3],
                     'id'      => 1
                   }.to_json
        response = BOILERPLATE.merge({'result' => 42}).to_json
        RestClient.should_receive(:post).with(SPEC_URL, expected, {:content_type => 'application/json'}).and_return(@resp_mock)
        @resp_mock.should_receive(:body).at_least(:once).and_return(response)
        @client = Client.new(SPEC_URL)
      end

      context "when using an array of args" do
        it "sends a request with the correct method and args" do
          @client['foo', [1,2,3]].should == 42
        end
      end
      context "when using a splat for args" do
        it "sends a request with the correct method and args" do
          @client['foo', 1, 2, 3].should == 42
        end
      end
    end

    describe "sending a single request" do
      context "when using positional parameters" do
        before(:each) do
          @expected = {
                       'jsonrpc' => '2.0',
                       'method'  => 'foo',
                       'params'  => [1,2,3],
                       'id'      => 1
                     }.to_json
        end
        it "sends a valid JSON-RPC request and returns the result" do
          response = BOILERPLATE.merge({'result' => 42}).to_json
          RestClient.should_receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json'}).and_return(@resp_mock)
          @resp_mock.should_receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL)
          client.foo(1,2,3).should == 42
        end
      end
    end

    describe "sending a batch request" do
      it "sends a valid JSON-RPC batch request and puts the results in the response objects" do
        batch = [
            {"jsonrpc" => "2.0", "method" => "sum", "params" => [1,2,4], "id" => "1"},
            {"jsonrpc" => "2.0", "method" => "subtract", "params" => [42,23], "id" => "2"},
            {"jsonrpc" => "2.0", "method" => "foo_get", "params" => [{"name" => "myself"}], "id" => "5"},
            {"jsonrpc" => "2.0", "method" => "get_data", "id" => "9"} 
        ].to_json

        response = [
            {"jsonrpc" => "2.0", "result" => 7, "id" => "1"},
            {"jsonrpc" => "2.0", "result" => 19, "id" => "2"},
            {"jsonrpc" => "2.0", "error" => {"code" => -32601, "message" => "Method not found."}, "id" => "5"},
            {"jsonrpc" => "2.0", "result" => ["hello", 5], "id" => "9"}
        ].to_json

        ClientHelper.stub!(:make_id).and_return('1', '2', '5', '9')
        RestClient.should_receive(:post).with(SPEC_URL, batch, {:content_type => 'application/json'}).and_return(@resp_mock)
        @resp_mock.should_receive(:body).at_least(:once).and_return(response)
        client = Client.new(SPEC_URL)

        sum = subtract = foo = data = nil
        Jimson::Client.batch(client) do |batch|
          sum = batch.sum(1,2,4)
          subtract = batch.subtract(42,23)
          foo = batch.foo_get('name' => 'myself')
          data = batch.get_data
        end

        sum.succeeded?.should be_true
        sum.is_error?.should be_false
        sum.result.should == 7

        subtract.result.should == 19

        foo.is_error?.should be_true
        foo.succeeded?.should be_false
        foo.error['code'].should == -32601

        data.result.should == ['hello', 5]
      end
    end

  end
end
