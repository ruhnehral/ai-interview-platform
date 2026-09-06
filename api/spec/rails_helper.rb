# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'database_cleaner/active_record'

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures')] if config.respond_to?(:fixture_paths=)
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  # Multi-tenancy: TenantScoped reads Current.tenant_id from RequestStore, which is
  # empty outside a request. Clear it between examples so a leaked tenant from one
  # spec cannot make another spec pass for the wrong reason.
  config.before do
    RequestStore.store.delete(:tenant_id)
  end
end
