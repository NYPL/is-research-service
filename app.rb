require 'httparty'
require 'json'
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

  path = event["path"]
  method = event["httpMethod"].downcase

  if method == 'get' && path == "/docs/is-research"
    return handle_swagger
  elsif method == 'get' && /\/api\/v0.1\/items\/[a-z-]+\/\w+\/is-research/.match?(path)
    return handle_is_research(event)
  else
    respond 400, "Bad method"
  end
end

def handle_swagger
  $swagger_doc = JSON.parse File.read('swagger.json') if $swagger_doc.nil?

  respond 200, $swagger_doc
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
