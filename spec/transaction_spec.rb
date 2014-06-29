require 'spec_helper'
require 'transaction'

describe Transaction do

let(:transaction) { Transaction.new }

  context "Transaction attribtues" do

  	it { is_expected.to respond_to(:user) }
  	it { is_expected.to respond_to(:amount) }
  	it { is_expected.to respond_to(:description) }
  	it { is_expected.to respond_to(:mitag) }
  	it { is_expected.to respond_to(:accdate) }
  	it { is_expected.to respond_to(:created_at) }
  	it { is_expected.to respond_to(:type) }
  end

  context "types of transaction" do

  	it 'can be either a credit transaction' do
  	  @credit_transaction = Credit.new
  	  expect(@credit_transaction).to be_a Credit
  	  expect(@credit_transaction).to be_a_kind_of Transaction
  	  expect(@credit_transaction).not_to be_a Debit
  	end

  	it 'or it a debit transaction' do
  	  @debit_transaction = Debit.new
  	  expect(@debit_transaction).to be_a Debit
  	  expect(@debit_transaction).to be_a_kind_of Transaction
  	  expect(@debit_transaction).not_to be_a Credit
  	end
  end
  

 end
