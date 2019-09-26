require 'dotenv'
require 'pry'
Dotenv.load('config/qa.env')

require_relative 'app'

def mock_event(nypl_source, id)
  init

  item = Item.new(nypl_source, id)

  return item.is_research?
end

sierra = 'sierra-nypl'
pul = 'recap-pul'

puts mock_event(sierra, "37314241")
