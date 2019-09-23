require 'httparty'
require 'json'
require 'pry-remote'

require_relative 'lib/item'
require_relative 'lib/platform_api_client'
require_relative 'lib/kms_client'
require_relative 'lib/nypl_core'

def init
  return if $initialized

  $nypl_core = NyplCore.new
  $platform_api = PlatformApiClient.new

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

sierra = 'sierra-nypl'
pul = 'recap-pul'

item = Item.new(pul, "17746307")

puts item.is_research

mock_event(pul, "17746307")
