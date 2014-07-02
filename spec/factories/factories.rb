
FactoryGirl.define do
  factory :user do
    uid '1234'
    email 'founduser@email.com'
    # Child of :user factory, since it's in the `factory :user` block
  end

  factory :transaction do
  	amount 1087.12
	  mitag "bankAccount"
	  association :user
  end

end

# FactoryGirl.define do
#   factory :transaction do
#     amount 1087.12
#     mitag "bankAccount"
#   end
# end