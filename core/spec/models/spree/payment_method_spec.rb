require 'spec_helper'

describe Spree::PaymentMethod, type: :model do
  context "visibility scopes" do
    before do
      [nil, '', 'both', 'front_end', 'back_end'].each do |display_on|
        Spree::Gateway::Test.create(
          name: 'Display Both',
          display_on: display_on,
          active: true,
          description: 'foofah'
        )
      end
    end

    it "should have 5 total methods" do
      expect(Spree::PaymentMethod.count).to eq(5)
    end

    describe "#available" do
      it "should return all methods available to front-end/back-end" do
        methods = Spree::PaymentMethod.available
        expect(methods.size).to eq(3)
        expect(methods.pluck(:display_on)).to eq(['both', 'front_end', 'back_end'])
      end
    end

    describe "#available_on_front_end" do
      it "should return all methods available to front-end" do
        methods = Spree::PaymentMethod.available_on_front_end
        expect(methods.size).to eq(2)
        expect(methods.pluck(:display_on)).to eq(['both', 'front_end'])
      end
    end

    describe "#available_on_back_end" do
      it "should return all methods available to back-end" do
        methods = Spree::PaymentMethod.available_on_back_end
        expect(methods.size).to eq(2)
        expect(methods.pluck(:display_on)).to eq(['both', 'back_end'])
      end
    end
  end

  describe "transaction limits" do 

    it "should be a valid payment method with a transaction_minimum" do
      expect(Spree::Gateway::Test.build(name: 'Display Both', display_on: "both", active: true, description: 'foofah', transaction_minimum: 47.11)).to be_valid
    end

    it "should be a valid payment method with a transaction_maximum" do
      expect(Spree::Gateway::Test.build(name: 'Display Both', display_on: "both", active: true, description: 'foofah', transaction_maximum: 13.37)).to be_valid
    end

    it "should be a valid payment method with a transaction_minimum and transaction_maximum" do
      expect(Spree::Gateway::Test.build(name: 'Display Both', display_on: "both", active: true, description: 'foofah', transaction_minimum: 50, transaction_maximum: 999)).to be_valid
    end
      
    it "should not create a payment method with a transaction_maximum lower then transaction_minimum" do
      expect(Spree::Gateway::Test.build(name: 'Display Both', display_on: "both", active: true, description: 'foofah', transaction_minimum: 500, transaction_maximum: 250)).not_to be_valid
    end

    it "should not create a payment method with a transaction_minimum that equals transaction_maximum" do
      expect(Spree::Gateway::Test.build(name: 'Display Both', display_on: "both", active: true, description: 'foofah', transaction_minimum: 10, transaction_maximum: 10)).not_to be_valid
    end

    it "should not create a payment method with a transaction_minimum lower then zero" do
      expect(Spree::Gateway::Test.build(name: 'Display Both', display_on: "both", active: true, description: 'foofah', transaction_minimum: -25)).not_to be_valid
    end

    it "should not create a payment method with a transaction_maximum lower then zero" do
      expect(Spree::Gateway::Test.build(name: 'Display Both', display_on: "both", active: true, description: 'foofah', transaction_minimum: -25)).not_to be_valid
    end


    it "should be available for an order" do 
      let(:order) { Spree::Order.create total: 100 }
      expect(Spree::Gateway::Test.build(name: 'Min 50', display_on: "both", active: true, transaction_minimum: 50).within_transaction_limits?(order)).to be_true
      expect(Spree::Gateway::Test.build(name: 'Max 200', display_on: "both", active: true, transaction_maximum: 200).within_transaction_limits?(order)).to be_true
      expect(Spree::Gateway::Test.build(name: 'Min 100', display_on: "both", active: true, transaction_minimum: 100).within_transaction_limits?(order)).to be_true
      expect(Spree::Gateway::Test.build(name: 'Max 100', display_on: "both", active: true, transaction_maximum: 100).within_transaction_limits?(order)).to be_true
    end

    it "should not be available for an order" do 
      let(:order) { Spree::Order.create total: 100 }
      expect(Spree::Gateway::Test.build(name: 'Min 500', display_on: "both", active: true, transaction_minimum: 500).within_transaction_limits?(order)).to_not be_true
      expect(Spree::Gateway::Test.build(name: 'Max 25', display_on: "both", active: true, transaction_maximum: 25).within_transaction_limits?(order)).to_not be_true
    end
  end

  describe '#auto_capture?' do
    class TestGateway < Spree::Gateway
      def provider_class
        Provider
      end
    end

    let(:gateway) { TestGateway.new }

    subject { gateway.auto_capture? }

    context 'when auto_capture is nil' do
      before(:each) do
        expect(Spree::Config).to receive('[]').with(:auto_capture).and_return(auto_capture)
      end

      context 'and when Spree::Config[:auto_capture] is false' do
        let(:auto_capture) { false }

        it 'should be false' do
          expect(gateway.auto_capture).to be_nil
          expect(subject).to be false
        end
      end

      context 'and when Spree::Config[:auto_capture] is true' do
        let(:auto_capture) { true }

        it 'should be true' do
          expect(gateway.auto_capture).to be_nil
          expect(subject).to be true
        end
      end
    end

    context 'when auto_capture is not nil' do
      before(:each) do
        gateway.auto_capture = auto_capture
      end

      context 'and is true' do
        let(:auto_capture) { true }

        it 'should be true' do
          expect(subject).to be true
        end
      end

      context 'and is false' do
        let(:auto_capture) { false }

        it 'should be true' do
          expect(subject).to be false
        end
      end
    end
  end

end
