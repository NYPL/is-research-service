require 'json'
require 'nypl_log_formatter'

require_relative 'lib/bib'

def init
  return if $initialized

  $nypl_core = NyplCore.new
  $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
  $platform_api = PlatformApiClient.new

  $mixed_bib_ids = File.read('data/mixed-bibs.csv')
  .split("\n")
  .map { |bnum| bnum.strip.sub(/^b/, '').chop }

  $initialized = true
end

def handle_event(event:, context:)
  init

  path = event["path"]
  method = event["httpMethod"].downcase

  if method == 'get' && path == "/docs/is-research"
    return handle_swagger
  elsif method == 'get' && /\/api\/v0.1\/(items|bibs)\/[a-z-]+\/\w+\/is-research/.match?(path)
    type = path.split('/')[3].chomp('s').capitalize
    type = Kernel.const_get(type)
    return handle_is_research(event, type)
  else
    respond 400, "Bad method"
  end
end

def handle_swagger
  $swagger_doc = JSON.parse File.read('swagger.json') if $swagger_doc.nil?

  respond 200, $swagger_doc
end

def handle_is_research(event, type)
  begin
    raise StandardError unless event["pathParameters"]
    raise ParameterError, "nypl source required" unless event["pathParameters"]["nyplSource"]
    raise ParameterError, "id required" unless event["pathParameters"]["id"]

    nypl_source = event["pathParameters"]["nyplSource"]
    id = event["pathParameters"]["id"]

    $logger.debug "Handling is-research for #{nypl_source} #{id}", { nypl_source: nypl_source, id: id}

    instance = type.new(nypl_source, id)

    respond 200, { nyplSource: instance.nypl_source, id: instance.id, isResearch: instance.is_research? }
  rescue ParameterError => e
    respond 400, message: "ParameterError: #{e.message}"
  rescue NotFoundError => e
    respond 404, message: "NotFoundError: #{e.message}"
  rescue DeletedError => e
    respond 410, message: "DeletedError: #{e.message}"
  rescue DataError => e
    respond 500, message: "DataError: #{e.message}"
  rescue => e
    respond 500, message: e.message
  end
end

def respond(statusCode = 200, body = nil)
  $logger.debug("Responding with #{statusCode}", body)
  { statusCode: statusCode, body: body.to_json, headers: {
      "Content-type": "application/json",
      "Access-Control-Allow-Origin": "*"
    }
  }
end
