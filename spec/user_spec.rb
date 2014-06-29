require 'spec_helper'
require 'user'

describe User do


let(:many_bank_transactions) do 
	trans = []
	10.times do  
		trans << FactoryGirl.create(:transaction)
	end
	return trans
end

let(:user) { User.new }
let(:user_with_transactions) { FactoryGirl.create(:user, transactions: many_bank_transactions) }

	context "User attribtues" do

		it { is_expected.to respond_to(:transactions) }
		#it { is_expected.to respond_to(:bookings) }

		it { is_expected.to respond_to(:id) }
		it { is_expected.to respond_to(:email) }
		it { is_expected.to respond_to(:uid) }
		it { is_expected.to respond_to(:provider) }
		
	end

	it 'should have transactions' do 
		expect(user_with_transactions.transactions.count).to eq 10
	end


 end
