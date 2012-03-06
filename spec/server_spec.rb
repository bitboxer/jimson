require 'spec_helper'
require 'rack/test'

module Jimson
    describe Server do
      include Rack::Test::Methods

      class TestHandler
        extend Jimson::Handler

        def subtract(a, b = nil)
          if a.is_a?(Hash)
            return a['minuend'] - a['subtrahend']
          else 
            return a - b
          end
        end

        def sum(a,b,c)
          a + b + c
        end

        def notify_hello(*args)
          # notification, doesn't do anything
        end

        def update(*args)
          # notification, doesn't do anything
        end

        def get_data
          ['hello', 5]
        end
      end

      INVALID_RESPONSE_EXPECTATION = {
                                        'jsonrpc' => '2.0',
                                        'error'   => {
                                                        'code' => -32600,
                                                        'message' => 'The JSON sent is not a valid Request object.'
                                                      },
                                        'id'      => nil
                                      }
      def app
        Server.new(TestHandler.new)
      end

      def post_json(hash)
        post '/', hash.to_json, {'Content-Type' => 'application/json'}
      end
      
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
            post_json(req)

            last_response.should be_ok
            resp = MultiJson.decode(last_response.body)
            resp.should == {
                             'jsonrpc' => '2.0',
                             'result'  => 4,
                             'id'      => 1
                           }
          end

          it "handles bignums" do
            req = {
                    'jsonrpc' => '2.0',
                    'method'  => 'subtract',
                    'params'  => [24, 20],
                    'id'      => 123456789_123456789_123456789
                  }
            post_json(req)

            last_response.should be_ok
            resp = MultiJson.decode(last_response.body)
            resp.should == {
                             'jsonrpc' => '2.0',
                             'result'  => 4,
                             'id'      => 123456789_123456789_123456789
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
            post_json(req)
            
            last_response.should be_ok
            resp = MultiJson.decode(last_response.body)
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
            post_json(req)
            last_response.body.should be_empty
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
          post_json(req)

          resp = MultiJson.decode(last_response.body)
          resp.should == {
                            'jsonrpc' => '2.0',
                            'error'   => {
                                            'code' => -32601,
                                            'message' => "Method 'foobar' not found."
                                          },
                            'id'      => 1
                          }
        end
      end

      describe "receiving a call for a method which exists but is not exposed" do
        it "returns an error response" do
          req = {
                  'jsonrpc' => '2.0',
                  'method'  => 'object_id',
                  'id'      => 1
                }
          post_json(req)

          resp = MultiJson.decode(last_response.body)
          resp.should == {
                            'jsonrpc' => '2.0',
                            'error'   => {
                                            'code' => -32601,
                                            'message' => "Method 'object_id' not found."
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
          post_json(req)

          resp = MultiJson.decode(last_response.body)
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
          post '/', req, {'Content-type' => 'application/json'}

          resp = MultiJson.decode(last_response.body)
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
                  }
            post_json(req)
            resp = MultiJson.decode(last_response.body)
            resp.should == INVALID_RESPONSE_EXPECTATION 
          end
        end

        context "when the request is an empty batch" do
          it "returns an error response" do
            req = []
            post_json(req)
            resp = MultiJson.decode(last_response.body)
            resp.should == INVALID_RESPONSE_EXPECTATION
          end
        end

        context "when the request is an invalid batch" do
          it "returns an error response" do
            req = [1,2]
            post_json(req)
            resp = MultiJson.decode(last_response.body)
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
                   ]
            post_json(reqs)
            resp = MultiJson.decode(last_response.body)
            resp.should == [
                    {'jsonrpc' => '2.0', 'result' => 7, 'id' => '1'},
                    {'jsonrpc' => '2.0', 'result' => 19, 'id' => '2'},
                    {'jsonrpc' => '2.0', 'error' => {'code' => -32600, 'message' => 'The JSON sent is not a valid Request object.'}, 'id' => nil},
                    {'jsonrpc' => '2.0', 'error' => {'code' => -32601, 'message' => "Method 'foo.get' not found."}, 'id' => '5'},
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
            post_json(req)
            last_response.body.should be_empty
          end
        end
      end

      describe "receiving a 'system.' request" do
        context "when the request is 'isAlive'" do
          it "returns response 'true'" do
            req = {
                    'jsonrpc' => '2.0',
                    'method'  => 'system.isAlive',
                    'params'  => [],
                    'id'      => 1
                  }
            post_json(req)

            last_response.should be_ok
            resp = MultiJson.decode(last_response.body)
            resp.should == {
                             'jsonrpc' => '2.0',
                             'result'  => true,
                             'id'      => 1
                           }
          end
        end
        context "when the request is 'listMethods'" do
          it "returns response with all listMethods on the handler as strings" do
            req = {
                    'jsonrpc' => '2.0',
                    'method'  => 'system.listMethods',
                    'params'  => [],
                    'id'      => 1
                  }
            post_json(req)

            last_response.should be_ok
            resp = MultiJson.decode(last_response.body)
            resp.should == {
                             'jsonrpc' => '2.0',
                             'result'  => ['subtract', 'sum', 'notify_hello', 'update', 'get_data'].sort,
                             'id'      => 1
                           }
          end
        end
      end
  end
end
