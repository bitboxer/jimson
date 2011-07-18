module Jimson
  describe Client do
    RESPONSE_BOILERPLATE = {'jsonrpc' => '2.0', 'id' => 1}

    before(:each) do
      @http_mock = mock('http')
      Patron::Session.stub!(:new).and_return(@http_mock)
      @http_mock.should_receive(:base_url=).with(SPEC_URL)
      ClientHelper.stub!(:make_id).and_return(1)
    end

    after(:each) do
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
        it "sends a valid JSON-RPC request" do
          @http_mock.should_receive(:post).with('', @expected).and_return(RESPONSE_BOILERPLATE)
          client = Client.new(SPEC_URL)
          client.foo(1,2,3)
        end
        it "returns the result from the server" do
          response = RESPONSE_BOILERPLATE.merge({'result' => 42})
          @http_mock.should_receive(:post).with('', @expected).and_return(response)
          client = Client.new(SPEC_URL)
          client.foo(1,2,3).should == 42
        end
      end
    end

  end
end
