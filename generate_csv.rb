require "pry"
require 'dotenv'
require 'nypl_log_formatter'
require "json"
require 'pg'
require 'csv'

require_relative 'lib/item'
require_relative 'lib/nypl_core'
require_relative 'lib/errors'

Dotenv.load('config/local.env')

environment = :development

params = {
  development: {
    limit: 10,
    from_bib_id: '0',
    institution: 'sierra-nypl'
  },
}

def init
  return if $initialized

  $nypl_core = NyplCore.new
  $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
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

  ids = results.field_values('id')

  if ids.empty?
    puts "Got through the bibs!"
    break
  end

  conn.close

  results.each do |item|
    stringified_bib_id_array = item["bib_ids"]
    bib_ids = JSON.parse stringified_bib_id_array
    if bib_ids.any?
      binding.pry
      item = Item.new(params[environment][:institution], )
    end
  end

  break
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
