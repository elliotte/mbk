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
let(:user_to_find) { FactoryGirl.create(:user) }
let(:user_with_transactions) { FactoryGirl.create(:user, transactions: many_bank_transactions) }

	context "User attribtues" do
		it { is_expected.to respond_to(:transactions) }
		it { is_expected.to respond_to(:id) }
		it { is_expected.to respond_to(:email) }
		it { is_expected.to respond_to(:uid) }
	end

	it 'should have transactions' do 
		expect(user_with_transactions.transactions.count).to eq 10
	end

	it 'should create a user with no uid found' do
		expect(User.first_or_create(uid: '1234').email).to eq nil
	end

	it 'should find the user if created' do
		user_to_find
		uid = '1234'
		expect(User.first_or_create(uid: uid).email).to eq 'founduser@email.com'
	end


 end
