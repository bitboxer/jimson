require 'spec_helper'

module Jimson
    describe Server do

      before(:each) do
        @sess = Patron::Session.new
        @sess.base_url = SPEC_URL
      end

      describe "receiving a request with positional parameters" do
        context "when no errors occur" do
          it "returns a response with 'result'" do
            req = {
                    'jsonrpc' => '2.0',
                    'method'  => 'subtract',
                    'params'  => [24, 20],
                    'id'      => 1
                  }
            resp = JSON.parse(@sess.post('/', req.to_json).body)
            resp.should == {
                             'jsonrpc' => '2.0',
                             'result'  => 4,
                             'id'      => 1
                           }
          end
        end
      end

      describe "receiving a request with named parameters" do
        context "when no errors occur" do
          it "returns a response with 'result'" do
            req = {
                    'jsonrpc' => '2.0',
                    'method'  => 'n_subtract',
                    'params'  => {'subtrahend'=> 24, 'minuend' => 20},
                    'id'      => 1
                  }
            resp = JSON.parse(@sess.post('/', req.to_json).body)
            resp.should == {
                             'jsonrpc' => '2.0',
                             'result'  => 4,
                             'id'      => 1
                           }
          end
        end
      end

      describe "receiving a notification" do
        context "when no errors occur" do
          it "returns no response" do
            req = {
                    'jsonrpc' => '2.0',
                    'method'  => 'subtract',
                    'params'  => [24,20]
                  }
            resp = @sess.post('/', req.to_json).body
            resp.should be_empty
          end
        end
      end

  end
end
