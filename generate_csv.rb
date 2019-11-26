require "pry"
require 'httparty'
require 'aws-sdk-kms'
require 'dotenv'
require 'nypl_log_formatter'
require "json"

require_relative 'lib/bib'
require_relative 'lib/item'
require_relative 'lib/platform_api_client'
require_relative 'lib/kms_client'
require_relative 'lib/nypl_core'
require_relative 'lib/errors'

Dotenv.load('config/qa.env')
Dotenv.load('config/.aws')

bibs_file = '../data_files/bibs.txt'
is_research_file = "bibs_is_research2.json"

def init
  return if $initialized

  $nypl_core = NyplCore.new
  $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
  $platform_api = PlatformApiClient.new

  $initialized = true
end

init

CSV.open(is_research_file, "w+") do |csv|
  CSV.open("errors.csv", "w+") do |error_csv|
    csv << ["ID", "RESEARCH"]
    error_csv << ["ID", "ERROR"]
    File.readlines(bibs_file).each do |line|
      begin
        id = line.strip
        bib = Bib.new("sierra-nypl", id)
        is_research = bib.is_research?
        csv << [id, is_research]
      rescue => e
        error_csv << [id, e]
      end
    end
  end
end
