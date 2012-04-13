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


    describe '#draw' do
      context 'when given non-nested namespaces' do
        it 'takes a block with a DSL to set the root and namespaces' do
          router.draw do
            root 'foo'
            namespace 'ns', 'bar'
          end

          router.handler_for_method('hi').should == 'foo'
          router.handler_for_method('ns.hi').should == 'bar'
        end
      end

      context 'when given nested namespaces' do
        it 'takes a block with a DSL to set the root and namespaces' do
          router.draw do
            root 'foo'
            namespace 'ns1' do
              root 'blah'
              namespace 'ns2', 'bar'
            end
          end

          router.handler_for_method('hi').should == 'foo'
          router.handler_for_method('ns1.hi').should == 'blah'
          router.handler_for_method('ns1.ns2.hi').should == 'bar'
        end
      end
    end

    describe '#jimson_methods' do
      it 'returns an array of namespaced method names from all registered handlers' do
        router.draw do
          root RouterFooHandler.new
          namespace 'foo', RouterBarHandler.new
        end

        router.jimson_methods.sort.should == ['hi', 'foo.bye'].sort
      end
    end

  end
end
