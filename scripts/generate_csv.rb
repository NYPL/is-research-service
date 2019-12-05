require "pry"
require 'dotenv'
require 'nypl_log_formatter'
require "json"
require 'pg'
require 'csv'
require './lib/nypl_core.rb'
require './lib/errors.rb'

require_relative 'utils'

Dotenv.load('./config/local.env')

environment = :development

params = {
  development: {
    limit: 10000,
    from_bib_id: '0',
    institution: 'sierra-nypl'
  },
}

def init
  return if $initialized

  $nypl_core = NyplCore.new
  $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
  $mixed_bib_ids = nil
  @log_data = {}
  # $platform_api = PlatformApiClient.new

  $initialized = true
end

init

from_bib_id = params[environment][:from_bib_id]

is_research_csv = CSV.open(File.join('is_research.csv'), 'w+')

iterations = 0

while true
  conn = PG.connect( host: 'localhost', dbname: 'itemservice', user: 'itemservice')

  results = conn.exec(
    "select id, location, fixed_fields, bib_ids from item " +
    "where nypl_source='sierra-nypl' and deleted is FALSE and " +
    "id > '#{from_bib_id}' " +
    "order by id limit #{params[environment][:limit]}"
  )

  ids = results.field_values 'id'

  if ids.empty?
    puts "Got through the bibs!"
    break
  end

  conn.close

  results.each do |item|
    bib_ids = JSON.parse item["bib_ids"]
    if bib_ids.any?
      fixed_fields = JSON.parse item["fixed_fields"]
      location = JSON.parse item["location"]

      next if !fixed_fields["61"] || !fixed_fields["61"]["value"] || !location["code"]

      item_data = {
        nypl_source: "sierra-nypl",
        id: item["id"],
        item_type_code: fixed_fields["61"]["value"],
        location_code: location["code"]
      }

      bib_ids.each do |bib_id|
        result = is_research? item_data

        puts result

        break if result == false
      end
    end
  end
end

# CSV.open(is_research_file, "w+") do |csv|
#   CSV.open("errors.csv", "w+") do |error_csv|
#     csv << ["ID", "RESEARCH"]
#     error_csv << ["ID", "ERROR"]
#     File.readlines(bibs_file).each do |line|
#       begin
#         id = line.strip
#         bib = Bib.new("sierra-nypl", id)
#         is_research = bib.is_research?
#         csv << [id, is_research]
#       rescue => e
#         error_csv << [id, e]
#       end
#     end
#   end
# end
