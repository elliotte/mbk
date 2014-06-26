FactoryGirl.define do
  factory :user do
    provider 'Test'
    uid '1234'
    email 'a@gmail.com'
    # Child of :user factory, since it's in the `factory :user` block
  end
end