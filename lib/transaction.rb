class Transaction

include DataMapper::Resource

	  property :id,     Serial # Serial means that it will be auto-incremented for every record
	  belongs_to :user
	  property :amount, Float
	  property :description, String
	  property :mitag, String
	  property :accdate, DateTime
	  property :created_at, DateTime
	  property :type, Discriminator

end


class Credit < Transaction

end

class Debit < Transaction

end

