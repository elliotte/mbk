require 'spec_helper'
require 'trial_balance'

describe TrialBalance do

let(:many_bank_transactions) do 
  trans = []
    10.times do  
      trans << FactoryGirl.create(:transaction)
    end
    return trans
end

let(:user) { User.new }
let(:user_with_transactions) { FactoryGirl.create(:user, transactions: many_bank_transactions) }

   context "initializing a trialBalance Object" do



  end


 end
