require 'rails_helper'
require_relative 'support/iam_helpers.rb'

require_relative '../db/migrate/20170608165435_create_group_mappings'
CreateGroupMappings.new.migrate(:up) unless ActiveRecord::Base.connection.table_exists? 'mozilla_iam_group_mappings'

SiteSetting.auth0_client_id = 'the_best_client_id'

RSpec.configure do |c|
  c.include IAMHelpers
end
