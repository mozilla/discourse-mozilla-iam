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
require_relative "support/dinopark_shared_examples.rb"

SiteSetting.auth0_client_id = 'the_best_client_id'

RSpec.configure do |c|
  c.include IAMHelpers
end
