require 'spec_helper'
require 'ledger_tags'

describe LedgerTags do

  context "Ledger attribtues" do
  	
  end

  context "types of ledgerTags" do

  	it 'should list SME ledgeraccounts' do
  	   expect(LedgerTags.bookkeeping_sme[:balance_sheet]).to eq ["bankAccount", "salesBook", "purchaseBook"]
       expect(LedgerTags.bookkeeping_sme[:profit_and_loss]).to eq ["Revenue_1", "Revenue_2", "Revenue_3", "costOfSale_1", "costOfSale_1", "costOfSale_1"]
  	end

  	
  end
  

 end
