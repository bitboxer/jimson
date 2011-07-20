require 'spec_helper'

module Jimson
    describe Server do

      INVALID_RESPONSE_EXPECTATION = {
                                        'jsonrpc' => '2.0',
                                        'error'   => {
                                                        'code' => -32600,
                                                        'message' => 'The JSON sent is not a valid Request object.'
                                                      },
                                        'id'      => nil
                                      }
      before(:each) do
        @url = SPEC_URL
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
            resp = JSON.parse(RestClient.post(@url, req.to_json).body)
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
                    'method'  => 'subtract',
                    'params'  => {'subtrahend'=> 20, 'minuend' => 24},
                    'id'      => 1
                  }
            resp = JSON.parse(RestClient.post(@url, req.to_json).body)
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
                    'method'  => 'update',
                    'params'  => [1,2,3,4,5]
                  }
            resp = RestClient.post(@url, req.to_json).body
            resp.should be_empty
          end
        end
      end

      describe "receiving a call for a non-existent method" do
        it "returns an error response" do
          req = {
                  'jsonrpc' => '2.0',
                  'method'  => 'foobar',
                  'id'      => 1
                }
          resp = JSON.parse(RestClient.post(@url, req.to_json).body)
          resp.should == {
                            'jsonrpc' => '2.0',
                            'error'   => {
                                            'code' => -32601,
                                            'message' => 'Method not found.'
                                          },
                            'id'      => 1
                          }
        end
      end

      describe "receiving a call with the wrong number of params" do
        it "returns an error response" do
          req = {
                  'jsonrpc' => '2.0',
                  'method'  => 'subtract',
                  'params'  => [1,2,3],
                  'id'      => 1
                }
          resp = JSON.parse(RestClient.post(@url, req.to_json).body)
          resp.should == {
                            'jsonrpc' => '2.0',
                            'error'   => {
                                            'code' => -32602,
                                            'message' => 'Invalid method parameter(s).'
                                          },
                            'id'      => 1
                          }
        end
      end

      describe "receiving invalid JSON" do
        it "returns an error response" do
          req = {
                  'jsonrpc' => '2.0',
                  'method'  => 'foobar',
                  'id'      => 1
                }.to_json
          req += '}' # make the json invalid
          resp = JSON.parse(RestClient.post(@url, req).body)
          resp.should == {
                            'jsonrpc' => '2.0',
                            'error'   => {
                                            'code' => -32700,
                                            'message' => 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.'
                                          },
                            'id'      => nil
                          }
        end
      end

      describe "receiving an invalid request" do
        context "when the request is not a batch" do
          it "returns an error response" do
            req = {
                    'jsonrpc' => '2.0',
                    'method'  => 1 # method as int is invalid
                  }.to_json
            resp = JSON.parse(RestClient.post(@url, req).body)
            resp.should == INVALID_RESPONSE_EXPECTATION 
          end
        end

        context "when the request is an empty batch" do
          it "returns an error response" do
            req = [].to_json
            resp = JSON.parse(RestClient.post(@url, req).body)
            resp.should == INVALID_RESPONSE_EXPECTATION
          end
        end

        context "when the request is an invalid batch" do
          it "returns an error response" do
            req = [1,2].to_json
            resp = JSON.parse(RestClient.post(@url, req).body)
            resp.should == [INVALID_RESPONSE_EXPECTATION, INVALID_RESPONSE_EXPECTATION] 
          end
        end
      end

      describe "receiving a valid batch request" do
        context "when not all requests are notifications" do
          it "returns an array of responses" do
            reqs = [
                      {'jsonrpc' => '2.0', 'method' => 'sum', 'params' => [1,2,4], 'id' => '1'},
                      {'jsonrpc' => '2.0', 'method' => 'notify_hello', 'params' => [7]},
                      {'jsonrpc' => '2.0', 'method' => 'subtract', 'params' => [42,23], 'id' => '2'},
                      {'foo' => 'boo'},
                      {'jsonrpc' => '2.0', 'method' => 'foo.get', 'params' => {'name' => 'myself'}, 'id' => '5'},
                      {'jsonrpc' => '2.0', 'method' => 'get_data', 'id' => '9'} 
                   ].to_json
            resp = JSON.parse(RestClient.post(@url, reqs).body)
            resp.should == [
                    {'jsonrpc' => '2.0', 'result' => 7, 'id' => '1'},
                    {'jsonrpc' => '2.0', 'result' => 19, 'id' => '2'},
                    {'jsonrpc' => '2.0', 'error' => {'code' => -32600, 'message' => 'The JSON sent is not a valid Request object.'}, 'id' => nil},
                    {'jsonrpc' => '2.0', 'error' => {'code' => -32601, 'message' => 'Method not found.'}, 'id' => '5'},
                    {'jsonrpc' => '2.0', 'result' => ['hello', 5], 'id' => '9'}
            ]
          end
        end

        context "when all the requests are notifications" do
          it "returns no response" do
            req = [
                    {
                      'jsonrpc' => '2.0',
                      'method'  => 'update',
                      'params'  => [1,2,3,4,5]
                    },
                    {
                      'jsonrpc' => '2.0',
                      'method'  => 'update',
                      'params'  => [1,2,3,4,5]
                    }
                  ]
            resp = RestClient.post(@url, req.to_json).body
            resp.should be_empty
          end
        end
      end

  end
end
