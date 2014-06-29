class Booking

	attr_reader :amounts
	attr_reader :booking_type
	attr_reader :debits
	attr_reader :credits
	attr_reader :user_id

	def initialize user_id, transaction_info, booking_type
		@amounts = transaction_info
		@booking_type = booking_type
		@user_id = user_id
		@debits = []
		@credits = []
	end

	def number_of_amounts 
		@amounts.count
	end

	def pop_amount_from_booking_list
		@amounts.pop
	end
	
	def build_a_user_debit amount_data
		amount_in_decimals = amount_data.fetch("value").to_f
		mitag_for_transaction = amount_data.fetch("mitag")
		Debit.new(amount: amount_in_decimals, mitag: mitag_for_transaction, user_id: @user_id)
	end

	def build_a_user_credit amount_data
		amount_in_decimals = amount_data.fetch("value").to_f
		mitag_for_transaction = amount_data.fetch("mitag")
		Credit.new(amount: amount_in_decimals, mitag: mitag_for_transaction, user_id: @user_id)
	end

	def build_a_bank_credit amount_data
		amount_in_decimals = amount_data.fetch("value").to_f
		Credit.new(amount: amount_in_decimals, mitag: "BankAccount", user_id: @user_id)
	end

	def build_a_bank_debit amount_data
		amount_in_decimals = amount_data.fetch("value").to_f
		Debit.new(amount: amount_in_decimals, mitag: "BankAccount", user_id: @user_id)
	end

	def hold_debit_for_validation new_debit
		@debits << new_debit
	end

	def hold_credit_for_validation new_credit
		@credits << new_credit
	end	

	def get_unsaved_debit_amounts
		@debits.map { |d| d.amount }
	end

	def get_unsaved_credit_amounts
		@credits.map { |d| d.amount }
	end

	def sum_list amounts_array
		amounts_array.count == 1 ? amounts_array.pop : amounts_array.inject(:+)
	end

	def transaction_debit_and_credit_amounts_equal?
		sum_list(get_unsaved_credit_amounts) == sum_list(get_unsaved_debit_amounts)
	end

	def create_transaction_from_holding_debit
		@debits.pop.save
	end

	def create_transaction_from_holding_credit
		@credits.pop.save
	end

	def create_debits_and_credits
		if transaction_debit_and_credit_amounts_equal?
			create_transaction_from_holding_credit
			create_transaction_from_holding_debit
		else
			"Nothing booked"
		end
	end

	def more_than_one_amount_added?
		@amounts.count > 1
	end

	def amounts_still_unbooked?
		@amounts.count > 0
	end

	def iterate_amounts_and_create_cashbook_payments
		while amounts_still_unbooked? do
			data = pop_amount_from_booking_list
			hold_debit_for_validation(build_a_user_debit(data))
			hold_credit_for_validation(build_a_bank_credit(data))
			create_debits_and_credits
		end
	end

	def iterate_amounts_and_create_cashbook_receipts
		while amounts_still_unbooked? do
			data = pop_amount_from_booking_list
			hold_debit_for_validation(build_a_user_credit(data))
			hold_credit_for_validation(build_a_bank_debit(data))
			create_debits_and_credits
		end
	end

	# def build_bank_credits
	# 	@amounts.each do |bank_credit|
	# 		amount_in_decimals = bank_credit.fetch("value").to_f
	# 	  	@transaction_credit = @transaction_collection.create(amount: amount_in_decimals, mitag: "BankAccount", type: 'Credit')
	# 	end
	# 	# think on map or each here as per below.  Can run checks of map e.g. output.count == amounts.count
	# end


	# def build_debits_from_user_bank_payments
	# 	@amounts.each do |cost_debit|	
	# 		amount_in_decimals = cost_debit.fetch("value").to_f
	# 	  	@transaction_debit = @transaction_collection.create(amount: amount_in_decimals, mitag: cost_debit.fetch("mitag"), type: 'Debit')
	# 	end
	# end


	# debitf build_a_transaction_debit data
	# 	amount_in_decimals = data.fetch("value").to_f
	# 	{amount: amount_in_decimals, mitag: data.fetch("mitag")}
	# end

	# def add_to_user_collection data
	# 	@transaction_collection.create(build_a_transaction_debit(data))
	# end

end

	