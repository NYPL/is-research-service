require 'httparty'
require 'json'
require 'pry'
require 'nypl_log_formatter'

require_relative 'lib/item'
require_relative 'lib/platform_api_client'
require_relative 'lib/kms_client'
require_relative 'lib/nypl_core'

def init
  return if $initialized

  $nypl_core = NyplCore.new
  $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
  $platform_api = PlatformApiClient.new


  $initialized = true
end

def handle_event(event:, context:)
  init

  nypl_source = event["pathParameters"]["nypl_source"]
  id = event["pathParameters"]["id"]

  item = Item.new(nypl_source, id)

  return handle_is_research(item)
end

def handle_is_research(item)
  begin

    respond 200, { is_research: item.is_research }
  rescue StandardError => e
    respond 400, message: e.message
  end
end

def respond(statusCode = 200, body = nil)
  $logger.debug("Responding with #{statusCode}", body)
  { statusCode: statusCode, body: body.to_json, headers: { "Content-type": "application/json" } }
end
