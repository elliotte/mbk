class DoubleEntry 

	def self.book_transactions booking_amounts
		if booking_amounts.booking_type == "user_bank_payments"
			booking_amounts.iterate_amounts_and_create_cashbook_payments
		else
			raise "nae"
		end
	end
end