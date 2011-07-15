module Jimson
  describe Client do

    before(:all) do
      FakeWeb.allow_net_connect = false
    end

    after(:all) do
      FakeWeb.allow_net_connect = true
    end

    describe "sending a single request" do
      context "when using positional parameters" do
        it "sends a valid JSON-RPC request" do
          expected = {
                       'jsonrpc' => '2.0',
                       'method'  => 'foo',
                       'params'  => [1,2,3],
                       'id'      => 1
                     }.to_json
          http_mock = mock('http')
          Patron::Session.stub!(:new).and_return(http_mock)
          http_mock.should_receive(:base_url=).with(SPEC_URL)
          http_mock.should_receive(:post).with('', expected)
          ClientHelper.stub!(:make_id).and_return(1)
          client = Client.new(SPEC_URL)
          client.foo(1,2,3)
        end
      end
    end

  end
end
