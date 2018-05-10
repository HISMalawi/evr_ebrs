# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!
require "bantu_soundex"
require "csv"
require "simple_elastic_search"
require "levenshtein"
require "action_matrix"
require "person_service"
require "lib"
require "zebra_printer"

