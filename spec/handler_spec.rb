require 'spec_helper'

module Jimson
  describe Handler do

    class FooHandler
      extend Jimson::Handler

      jimson_expose :to_s, :bye

      jimson_exclude :hi, :bye

      def hi
        'hi'
      end

      def bye
        'bye'
      end

      def to_s
        'foo'
      end

      def so_exposed
        "I'm so exposed!"
      end
    end

    let(:foo) { FooHandler.new }

    describe "#jimson_expose" do
      it "exposes a method even if it was defined on Object" do
        expect(foo.class.jimson_exposed_methods).to include('to_s')
      end
    end

    describe "#jimson_exclude" do
      context "when a method was not explicitly exposed" do
        it "excludes the method" do
          expect(foo.class.jimson_exposed_methods).to_not include('hi')
        end
      end
      context "when a method was explicitly exposed" do
        it "does not exclude the method" do
          expect(foo.class.jimson_exposed_methods).to include('bye')
        end
      end
    end

    describe "#jimson_exposed_methods" do
      it "doesn't include methods defined on Object" do
        expect(foo.class.jimson_exposed_methods).to_not include('object_id')
      end
      it "includes methods defined on the extending class but not on Object" do
        expect(foo.class.jimson_exposed_methods).to include('so_exposed')
      end
    end

  end
end

