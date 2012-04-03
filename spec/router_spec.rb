require 'spec_helper'

module Jimson
  describe Router do

    let(:router) { Router.new }

    describe '#draw' do
      it 'takes a block with a DSL to set the root and namespaces' do
        router.draw do
          root 'foo'
          namespace 'ns', 'bar'
        end

        router.handler_for_method('hi').should == 'foo'
        router.handler_for_method('ns.hi').should == 'bar'
      end
    end

  end
end
