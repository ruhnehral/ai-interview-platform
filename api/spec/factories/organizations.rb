# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    sequence(:name)       { |n| "Org #{n}" }
    sequence(:scheme)     { |n| "org-#{n}" }
    sequence(:identifier) { |n| "identifier-#{n}" }
    sequence(:host)       { |n| "org#{n}.example.com" }
  end
end
