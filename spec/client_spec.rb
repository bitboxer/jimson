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
          client = Client.new(CLIENT_SPEC_URL)
          client.foo(1,2,3)
          req = JSON.parse(FakeWeb.last_request.body)
          req['jsonrpc'].should == '2.0'
          req['id'].should be_a(Fixnum)
          req['method'].should == 'foo'
          req['params'].should == [1,2,3]
        end
      end
    end

  end
end
