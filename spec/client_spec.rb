require 'spec_helper'

module Jimson
  describe Client do
    BOILERPLATE = {'jsonrpc' => '2.0', 'id' => 1}

    before(:each) do
      @resp_mock = double('http_response')
      allow(ClientHelper).to receive(:make_id).and_return(1)
    end

    after(:each) do
    end

    describe "hidden methods" do
      it "should reveal inspect" do
        expect(Client.new(SPEC_URL).inspect).to match /Jimson::Client/
      end

      it "should reveal to_s" do
        expect(Client.new(SPEC_URL).to_s).to match /Jimson::Client/
      end
    end

    describe "#[]" do
      before(:each) do
        @client = Client.new(SPEC_URL)
      end

      context "when using a symbol to specify a namespace" do
        it "sends the method prefixed with the namespace in the request" do
          expected = MultiJson.encode({
           'jsonrpc' => '2.0',
           'method'  => 'foo.sum',
           'params'  => [1,2,3],
           'id'      => 1
          })
          response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
          expect(RestClient).to receive(:post).with(SPEC_URL, expected, {:content_type => 'application/json'}).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          expect(@client[:foo].sum(1, 2, 3)).to eq 42
        end

        context "when the namespace is nested" do
          it "sends the method prefixed with the full namespace in the request" do
            expected = MultiJson.encode({
             'jsonrpc' => '2.0',
             'method'  => 'foo.bar.sum',
             'params'  => [1,2,3],
             'id'      => 1
            })
            response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
            expect(RestClient).to receive(:post).with(SPEC_URL, expected, {:content_type => 'application/json'}).and_return(@resp_mock)
            expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
            expect(@client[:foo][:bar].sum(1, 2, 3)).to eq 42
          end
        end
      end

      context "when sending positional arguments" do
        it "sends a request with the correct method and args" do
          expected = MultiJson.encode({
           'jsonrpc' => '2.0',
           'method'  => 'foo',
           'params'  => [1,2,3],
           'id'      => 1
          })
          response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
          expect(RestClient).to receive(:post).with(SPEC_URL, expected, {:content_type => 'application/json'}).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          expect(@client['foo', 1, 2, 3]).to eq 42
        end

        context "when one of the args is an array" do
          it "sends a request with the correct method and args" do
            expected = MultiJson.encode({
             'jsonrpc' => '2.0',
             'method'  => 'foo',
             'params'  => [[1,2],3],
             'id'      => 1
            })
            response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
            expect(RestClient).to receive(:post).with(SPEC_URL, expected, {:content_type => 'application/json'}).and_return(@resp_mock)
            expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
            expect(@client['foo', [1, 2], 3]).to eq 42
          end
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
          expect(RestClient).to receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json'}).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL)
          expect(client.foo(1,2,3)).to eq 42
        end

        it "sends a valid JSON-RPC request with custom options" do
          response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
          expect(RestClient).to receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json', :timeout => 10000}).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL, :timeout => 10000)
          expect(client.foo(1,2,3)).to eq 42
        end
      end

      context "when one of the parameters is an array" do
        it "sends a correct JSON-RPC request (array is preserved) and returns the result" do
          expected = MultiJson.encode({
            'jsonrpc' => '2.0',
            'method'  => 'foo',
            'params'  => [[1,2],3],
            'id'      => 1
          })
          response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
          expect(RestClient).to receive(:post).with(SPEC_URL, expected, {:content_type => 'application/json'}).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL)
          expect(client.foo([1,2],3)).to eq 42
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

        allow(ClientHelper).to receive(:make_id).and_return('1', '2', '5', '9')
        expect(RestClient).to receive(:post).with(SPEC_URL, batch, {:content_type => 'application/json'}).and_return(@resp_mock)
        expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
        client = Client.new(SPEC_URL)

        sum = subtract = foo = data = nil
        Jimson::Client.batch(client) do |batch|
          sum = batch.sum(1,2,4)
          subtract = batch.subtract(42,23)
          foo = batch.foo_get('name' => 'myself')
          data = batch.get_data
        end

        expect(sum.succeeded?).to be true
        expect(sum.is_error?).to be false
        expect(sum.result).to eq 7

        expect(subtract.result).to eq 19

        expect(foo.is_error?).to be true
        expect(foo.succeeded?).to be false
        expect(foo.error['code']).to eq -32601

        expect(data.result).to eq ['hello', 5]
      end
    end

    describe "error handling" do
      context "when an error occurs in the Jimson::Client code" do
        it "tags the raised exception with Jimson::Client::Error" do
          client_helper = ClientHelper.new(SPEC_URL)
          allow(ClientHelper).to receive(:new).and_return(client_helper)
          client = Client.new(SPEC_URL)
          allow(client_helper).to receive(:send_single_request).and_raise "intentional error"
          expect(lambda { client.foo }).to raise_error(Jimson::Client::Error)
        end
      end
    end

  end
end
