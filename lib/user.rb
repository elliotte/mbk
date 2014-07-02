class User

  include DataMapper::Resource

  property :id,     Serial # Serial means that it will be auto-incremented for every record
  property :email,     String
  has n, :transactions
  property :uid,     String

  def credits
    transactions.all(conditions: { :type => 'Credit' })
  end

  def debits
    transactions.all(conditions: { :type => 'Debit' })
  end

end


