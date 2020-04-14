require_relative 'platform_api_client'
require_relative 'nypl_core'

def init
  return if $initialized

  $nypl_core = NyplCore.new
  $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
  $platform_api = PlatformApiClient.new

  $initialized = true
end

class MarcRecord
  attr_reader :nypl_source, :id, :is_partner

  def initialize(nypl_source, id)
    init

    @nypl_source = nypl_source
    @id = id
    @log_data = {}
  end

  def is_partner?
    result = nypl_source == "recap-cul" || nypl_source == "recap-pul"
    @log_data[:is_partner?] = result
    return result
  end

  def get_platform_api_data(api_path)
    response = $platform_api.get(api_path)

    raise NotFoundError unless response["data"]

    response["data"]
  end
end
