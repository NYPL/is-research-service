require 'httparty'
require 'json'
require 'pry-remote'

require_relative 'lib/item'

def init
  return if $initialized

  $nypl_core = NyplCore.new

  $initialized = true
end

def mock_event(nypl_source, id)
  init

  item = item.new(nypl_source, id)
  return item.is_research
end

def handle_event(event:, context:)
  init
  # get_discovery_response("https://platform.nypl.org/api/v0.1/items?limit=1", key)
  {
    statusCode: 200,
    body: {
      message: "Hello World!",
      # location: response.body
    }.to_json
  }
end

def get_discovery_response(url, auth)

  binding.pry
end



# get_discovery_response("https://platform.nypl.org/api/v0.1/items?limit=1", key)
