if ENV["COVERALLS"] || ENV["SIMPLECOV"]
  require "simplecov"

  if ENV["COVERALLS"]
    require "coveralls"
    SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  end

  SimpleCov.start do
    root File.expand_path("../..", __FILE__)
    add_filter "spec/"
    add_filter "db/migrate"
    add_filter "gems/"
  end
end

require 'rails_helper'
require_relative 'support/iam_helpers.rb'
require_relative "support/shared_examples.rb"

require_relative '../db/migrate/20170608165435_create_group_mappings'
CreateGroupMappings.new.migrate(:up) unless ActiveRecord::Base.connection.table_exists? 'mozilla_iam_group_mappings'

SiteSetting.auth0_client_id = 'the_best_client_id'

RSpec.configure do |c|
  c.include IAMHelpers
end
