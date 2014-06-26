class User

  include DataMapper::Resource

  property :id,     Serial # Serial means that it will be auto-incremented for every record
  property :email,     String
  property :uid,     String
  property :provider,     String


end


