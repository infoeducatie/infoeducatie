FactoryBot.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end

  factory :user do
    email { generate(:email) }
    password { "TestP4ssW0rd" }

    first_name { "Anutsa" }
    last_name { "Stark" }
  end

  factory :confirmed_user, class: User do
    email { generate(:email) }
    password { "TestP4ssW0rd" }
    after(:create) { |user|
      user.confirm
      user.update_access_token!
    }

    first_name { "Ionut" }
    last_name { "Zapada" }
  end

  factory :valid_user_with_contestant, class: User do
    email { "test3@user.ro" }
    password { "TestP4ssW0rd" }
    first_name { "Ionut" }
    last_name { "Zapada" }

    after(:create) { |user|
      user.confirm

      user.update_access_token!

      contestant = create(:contestant)
      user.contestants << contestant
    }
  end
end
