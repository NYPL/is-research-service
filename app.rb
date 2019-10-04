require 'httparty'
require 'json'
require 'pry'
require 'nypl_log_formatter'

require_relative 'lib/item'
require_relative 'lib/platform_api_client'
require_relative 'lib/kms_client'
require_relative 'lib/nypl_core'
require_relative 'lib/errors'

def init
  return if $initialized

  $nypl_core = NyplCore.new
  $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
  $platform_api = PlatformApiClient.new

  $initialized = true
end

def handle_event(event:, context:)
  init

  return handle_is_research(event)
end

def handle_is_research(event)
  begin
    raise StandardError unless event["pathParameters"]
    raise ParameterError("nypl_source required") unless event["pathParameters"]["nypl_source"]
    raise ParameterError("id required") unless event["pathParameters"]["id"]

    nypl_source = event["pathParameters"]["nypl_source"]
    id = event["pathParameters"]["id"]

    $logger.debug "Handling is-research for #{nypl_source} #{id}", { nypl_source: nypl_source, id: id}

    item = Item.new(nypl_source, id)
    respond 200, { nyplSource: item.nypl_source, id: item.id, isResearch: item.is_research? }
  rescue ParameterError => e
    respond 400, message: "ParameterError: #{e.message}"
  rescue NotFoundError => e
    respond 404, message: "NotFoundError: #{e.message}"
  rescue DataError => e
    respond 500, message: "DataError: #{e.message}"
  rescue => e
    respond 500, message: e.message
  end
end

def respond(statusCode = 200, body = nil)
  $logger.debug("Responding with #{statusCode}", body)
  { statusCode: statusCode, body: body.to_json, headers: { "Content-type": "application/json" } }
end
