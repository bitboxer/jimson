require 'spec_helper'

module Jimson
  describe Router do

    let(:router) { Router.new }

    class RouterFooHandler
      extend Jimson::Handler

      def hi
        'hi'
      end
    end

    class RouterBarHandler
      extend Jimson::Handler

      def bye 
        'bye'
      end
    end

    class RouterBazHandler
      extend Jimson::Handler

      def meh 
        'mehkayla'
      end
    end


    describe '#draw' do
      context 'when given non-nested namespaces' do
        it 'takes a block with a DSL to set the root and namespaces' do
          router.draw do
            root RouterFooHandler
            namespace 'ns', RouterBarHandler
          end

          router.handler_for_method('hi').should be_a(RouterFooHandler)
          router.handler_for_method('ns.hi').should be_a(RouterBarHandler)
        end
      end

      context 'when given nested namespaces' do
        it 'takes a block with a DSL to set the root and namespaces' do
          router.draw do
            root RouterFooHandler
            namespace 'ns1' do
              root RouterBazHandler
              namespace 'ns2', RouterBarHandler
            end
          end

          router.handler_for_method('hi').should be_a(RouterFooHandler)
          router.handler_for_method('ns1.hi').should be_a(RouterBazHandler)
          router.handler_for_method('ns1.ns2.hi').should be_a(RouterBarHandler)
        end
      end
    end

    describe '#jimson_methods' do
      it 'returns an array of namespaced method names from all registered handlers' do
        router.draw do
          root RouterFooHandler
          namespace 'foo', RouterBarHandler
        end

        router.jimson_methods.sort.should == ['hi', 'foo.bye'].sort
      end
    end

  end
end
