require 'spec_helper'
require 'booking'
require 'user'

describe Booking do

let(:user) { FactoryGirl.create(:user)}
let(:user_data) { [{"value"=>"12.23", "mitag"=>"Cost", "accdate"=>""}, {"value"=>"14", "mitag"=>"Cost", "accdate"=>""}, {"value"=>"16.65", "mitag"=>"Cost", "accdate"=>""}, {"value"=>"432.45", "mitag"=>"", "accdate"=>""}, {"value"=>"546.87", "mitag"=>"", "accdate"=>""}] }
let(:type) { "user_bank_payments" }
let(:booking) { Booking.new(user.id, user_data, type) }
let(:unsaved_debit) { booking.build_a_user_debit(booking.pop_amount_from_booking_list) }
let(:unsaved_credit) { booking.build_a_bank_credit(booking.pop_amount_from_booking_list) }
let(:holding_debit) { booking.hold_debit_for_validation(unsaved_debit) }
let(:holding_credit) { booking.hold_credit_for_validation(unsaved_credit) }

let(:balanced_debit_and_credit_in_holding) do 
      debit = booking.build_a_user_debit({"value"=>"12.23", "mitag"=>"Cost", "accdate"=>""})
      credit = booking.build_a_bank_credit({"value"=>"12.23", "mitag"=>"Cost", "accdate"=>""})
      booking.hold_debit_for_validation(debit)
      booking.hold_credit_for_validation(credit)
end

    context "initializing a booking" do
      it 'should initialize with userId, amountsInfo and bookingType' do
        expect(booking.booking_type).to eq "user_bank_payments"
        expect(booking.amounts).to eq [{"value"=>"12.23", "mitag"=>"Cost", "accdate"=>""}, {"value"=>"14", "mitag"=>"Cost", "accdate"=>""}, {"value"=>"16.65", "mitag"=>"Cost", "accdate"=>""}, {"value"=>"432.45", "mitag"=>"", "accdate"=>""}, {"value"=>"546.87", "mitag"=>"", "accdate"=>""}]
        expect(booking.user_id).to eq User.last.id
      end
    end

   context "building debits and credits" do

    it 'can build an unsaved bank credit instance' do
      expect(unsaved_credit.mitag).to eq "BankAccount"
      expect(unsaved_credit.amount).to eq 546.87
      expect(unsaved_credit.id).to eq nil
      expect(unsaved_credit).to be_a Credit
    end

    it 'can add an unsaved bank credit to credits list for holding' do
      expect(booking.credits.count).to eq 0
      booking.hold_credit_for_validation(unsaved_credit)
      expect(booking.credits.count).to eq 1
    end

    it 'can build an unsaved debit instance from popped amount' do
      expect(unsaved_debit.amount).to eq 546.87
      expect(unsaved_debit.id).to eq nil
      expect(unsaved_debit).to be_a Debit
    end

    it 'can add unsaved debit to debits list for holding' do
      expect(booking.debits.count).to eq 0
      booking.hold_debit_for_validation(unsaved_debit)
      expect(booking.debits.count).to eq 1
    end

   end

   context "validating debits and credits" do

      it 'returns false if debit and credit amounts are not equal' do
        holding_debit
        holding_credit
        expect(booking.transaction_debit_and_credit_amounts_equal?).to eq false
      end

      it 'returns true if the debit and credit are equal' do
        balanced_debit_and_credit_in_holding
        expect(booking.transaction_debit_and_credit_amounts_equal?).to eq true
      end

      it 'doesnt save an unbalanced debit and credit' do
        holding_debit
        holding_credit
        expect(user.transactions.count).to eq 0
        expect(booking.credits.count).to eq 1
        expect(booking.debits.count).to eq 1
        expect(booking.create_debits_and_credits).to eq "Nothing booked"
        expect(booking.credits.count).to eq 1
        expect(booking.debits.count).to eq 1
        expect(user.transactions.count).to eq 0
      end

      it 'does save a balanced debit and credit' do
          balanced_debit_and_credit_in_holding
          expect(user.transactions.count).to eq 0
          expect(booking.credits.count).to eq 1
          expect(booking.debits.count).to eq 1
          expect(booking.create_debits_and_credits).to eq true
          expect(booking.credits.count).to eq 0
          expect(booking.debits.count).to eq 0
          expect(user.transactions.count).to eq 2
       end

   end  

   context "transaction debit and credits creation" do

      it 'can pop a debit and save as transaction debit' do
        holding_debit
        expect(user.transactions.count).to eq 0
        expect(booking.debits.count).to eq 1
        expect(booking.create_transaction_from_holding_debit).to eq true
        expect(user.transactions.count).to eq 1
        expect(booking.debits.count).to eq 0
      end

      it 'can pop a credit and save as transaction credit' do
        holding_credit
        expect(user.transactions.count).to eq 0
        expect(booking.credits.count).to eq 1
        expect(booking.create_transaction_from_holding_credit).to eq true
        expect(user.transactions.count).to eq 1
        expect(booking.credits.count).to eq 0
      end

   end

  context "booking bank payment transactions" do

      it 'should book ten transactions' do
        expect(user.transactions.count).to eq 0
        booking.iterate_amounts_and_create_cashbook_payments
        expect(user.transactions.count).to eq 10
      end

      it 'should have 5 credits' do
        booking.iterate_amounts_and_create_cashbook_payments
        user_credits = user.credits
        expect(user_credits.count).to eq 5
      end

      it 'should have 5 debits' do
        booking.iterate_amounts_and_create_cashbook_payments
        user_debits = user.debits
        expect(user_debits.count).to eq 5
      end

      it 'should have booked balanced credits and debits' do
        booking.iterate_amounts_and_create_cashbook_payments
        total_credits = user.credits.sum(:amount)
        total_debits = user.debits.sum(:amount)
        expect(total_credits).to eq total_debits
      end

      it 'should have booked BankAccount miTag credit transactions' do
        booking.iterate_amounts_and_create_cashbook_payments
        tags_from_credits = user.credits.map { |c| c.mitag }
        expect(tags_from_credits).to eq ["BankAccount", "BankAccount", "BankAccount", "BankAccount", "BankAccount"]
      end

      it 'should have booked 5 transactions with user miTags' do
        booking.iterate_amounts_and_create_cashbook_payments
        tags_from_debits = user.debits.map { |d| d.mitag }
        expect(tags_from_debits).to eq ["", "", "Cost", "Cost", "Cost"]
      end

  end

  context "booking bank receipt transactions" do

    it 'should book ten transactions' do
      expect(user.transactions.count).to eq 0
      booking.iterate_amounts_and_create_cashbook_receipts
      expect(user.transactions.count).to eq 10
    end

    it 'should have 5 credits' do
      booking.iterate_amounts_and_create_cashbook_receipts
      user_credits = user.credits
      expect(user_credits.count).to eq 5
    end

    it 'should have 5 debits' do
      booking.iterate_amounts_and_create_cashbook_receipts
      user_debits = user.debits
      expect(user_debits.count).to eq 5
    end

    it 'should have booked balanced credits and debits' do
      booking.iterate_amounts_and_create_cashbook_receipts
      total_credits = user.credits.sum(:amount)
      total_debits = user.debits.sum(:amount)
      expect(total_credits).to eq total_debits
    end

    it 'should have booked BankAccount miTag debit transactions' do
      booking.iterate_amounts_and_create_cashbook_receipts
      tags_from_debits = user.debits.map { |d| d.mitag }
      expect(tags_from_debits).to eq ["BankAccount", "BankAccount", "BankAccount", "BankAccount", "BankAccount"]
    end

    it 'should have booked 5 credit transactions with user miTags' do
      booking.iterate_amounts_and_create_cashbook_receipts
      tags_from_credits = user.credits.map { |c| c.mitag }
      expect(tags_from_credits).to eq ["", "", "Cost", "Cost", "Cost"]
    end

  end

  context "model helpers" do

    it 'knows the number of amounts in the booking list' do
      expect(booking.number_of_amounts).to eq 5
    end

    it 'can pop an amount from booking amounts list' do
      expect(booking.pop_amount_from_booking_list).to eq({"value"=>"546.87", "mitag"=>"", "accdate"=>""})
    end

    it 'can get amounts of unsaved debits' do
      holding_debit
      booking.hold_debit_for_validation(unsaved_debit)
      amounts = booking.get_unsaved_debit_amounts
      expect(amounts).to eq [546.87, 546.87]
    end

    it 'can get amounts of unsaved credits' do
      holding_credit
      booking.hold_credit_for_validation(unsaved_credit)
      amounts = booking.get_unsaved_credit_amounts
      expect(amounts).to eq [546.87, 546.87]
    end

    it 'can total an array of amounts' do
      amounts = [546.87, 546.87]
      expect(booking.sum_list(amounts)).to eq 1093.74
    end

    it 'returns total if only one amount' do
      amounts = [546.87]
      expect(booking.sum_list(amounts)).to eq 546.87
    end


    it 'should know if more than one amount is added' do
      expect(booking.more_than_one_amount_added?).to eq true
    end

    it 'should return false if no amounts are still unbooked' do
      5.times do 
        booking.amounts.pop
      end
      expect(booking.amounts_still_unbooked?).to eq false
    end 

  end
  # context "booking user bank payments" do

  #   it 'can build bank accounting credits' do
  #     expect(user.transactions.count).to eq 0
  #     booking.build_bank_credits
  #     expect(user.transactions.last).to be_a Credit
  #     expect(user.transactions.count).to eq 5
  #   end

  #   it 'can build accounting debits from bank credits' do
  #     expect(user.transactions.count).to eq 0
  #     booking.build_debits_from_user_bank_payments
  #     expect(user.transactions.last).to be_a Debit
  #     expect(user.transactions.count).to eq 5
  #   end

  #   it 'stores transaction amount as 2 decimal points' do
  #     booking.build_bank_credits
  #     expect(user.transactions.last.amount).to eq 546.78
  #   end

  # end
  
  # it 'can build a transaction debit' do
  #   type = "user_bank_payments"
  #   booking = Booking.new(user.id, user_data, type)
  #   tran = booking.build_a_transaction_debit({"value"=>"12.23", "mitag"=>"Cost", "accdate"=>""})
  #   expect(tran.fetch("amount")).to eq 12.23
  # end 

  #  it 'can add transaction to userCollection' do
  #   type = "user_bank_payments"
  #   booking = Booking.new(user.id, user_data, type)
  #   debit = booking.add_to_user_collection({"value"=>"12.23", "mitag"=>"Cost", "accdate"=>""})
  #   expect(user.transactions.last.amount).to eq 12.23
  # end 



 end

#booking = Booking.new(1, [{"value"=>"12.23", "mitag"=>"Cost", "accdate"=>""}, {"value"=>"14", "mitag"=>"Cost", "accdate"=>""}, {"value"=>"16.65", "mitag"=>"Cost", "accdate"=>""}, {"value"=>"432.45", "mitag"=>"", "accdate"=>""}, {"value"=>"546.87", "mitag"=>"", "accdate"=>""}], "hello")

#Transaction.create(amount: BigDecimal.new("12.34"), mitag: "Cost", type: 'Debit', user_id: 1)