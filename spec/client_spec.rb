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

    describe "hidden methods" do
      it "should reveal inspect" do
        Client.new(SPEC_URL).inspect.should match /Jimson::Client/
      end

      it "should reveal to_s" do
        Client.new(SPEC_URL).to_s.should match /Jimson::Client/
      end
    end

    describe "#[]" do
      before(:each) do
        expected = MultiJson.encode({
         'jsonrpc' => '2.0',
         'method'  => 'foo',
         'params'  => [1,2,3],
         'id'      => 1
        })
        response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
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
          @expected = MultiJson.encode({
                       'jsonrpc' => '2.0',
                       'method'  => 'foo',
                       'params'  => [1,2,3],
                       'id'      => 1
          })
        end
        it "sends a valid JSON-RPC request and returns the result" do
          response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
          RestClient.should_receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json'}).and_return(@resp_mock)
          @resp_mock.should_receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL)
          client.foo(1,2,3).should == 42
        end

        it "sends a valid JSON-RPC request with custom options" do
          response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
          RestClient.should_receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json', :timeout => 10000}).and_return(@resp_mock)
          @resp_mock.should_receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL, :timeout => 10000)
          client.foo(1,2,3).should == 42
        end

        it "sends a valid JSON-RPC request with custom content_type" do
          response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
          RestClient.should_receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json-rpc', :timeout => 10000}).and_return(@resp_mock)
          @resp_mock.should_receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL, :timeout => 10000, :content_type => 'application/json-rpc')
          client.foo(1,2,3).should == 42
        end
      end
    end

    describe "sending a batch request" do
      it "sends a valid JSON-RPC batch request and puts the results in the response objects" do
        batch = MultiJson.encode([
          {"jsonrpc" => "2.0", "method" => "sum", "params" => [1,2,4], "id" => "1"},
          {"jsonrpc" => "2.0", "method" => "subtract", "params" => [42,23], "id" => "2"},
          {"jsonrpc" => "2.0", "method" => "foo_get", "params" => [{"name" => "myself"}], "id" => "5"},
          {"jsonrpc" => "2.0", "method" => "get_data", "id" => "9"}
        ])

        response = MultiJson.encode([
          {"jsonrpc" => "2.0", "result" => 7, "id" => "1"},
          {"jsonrpc" => "2.0", "result" => 19, "id" => "2"},
          {"jsonrpc" => "2.0", "error" => {"code" => -32601, "message" => "Method not found."}, "id" => "5"},
          {"jsonrpc" => "2.0", "result" => ["hello", 5], "id" => "9"}
        ])

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

    describe "error handling" do
      context "when an error occurs in the Jimson::Client code" do
        it "tags the raised exception with Jimson::Client::Error" do
          client_helper = ClientHelper.new(SPEC_URL)
          ClientHelper.stub!(:new).and_return(client_helper)
          client = Client.new(SPEC_URL)
          client_helper.stub!(:send_single_request).and_raise "intentional error"
          lambda { client.foo }.should raise_error(Jimson::Client::Error)
        end
      end
    end

  end
end
