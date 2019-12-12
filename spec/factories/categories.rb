FactoryGirl.define do
  factory :category do
    title { Faker::Ancient.hero }
    short_title { Faker::Ancient.primordial }
    description { Faker::StarWars.quote }
    url { Faker::Internet.url }
    association :taxonomy

    trait :parent_category do
      title:'parent'
    end
  
    trait :sub_category do
      title:'parent'
    end

  end
end
