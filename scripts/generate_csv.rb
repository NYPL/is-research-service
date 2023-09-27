require "pry"
require 'dotenv'
require 'nypl_log_formatter'
require "json"
require 'pg'
require 'csv'
require 'set'
require './lib/nypl_core.rb'
require './lib/errors.rb'

require_relative 'utils'

Dotenv.load('./config/local.env')

environment = :development

params = {
  development: {
    limit: 100000,
    from_item_id: '0',
    institution: 'sierra-nypl'
  },
}

def init
  return if $initialized

  $nypl_core = NyplCore.new
  $logger = NyplLogFormatter.new(STDOUT, level: 'info')
  @log_data = {}

  $initialized = true
end

init

from_item_id = params[environment][:from_item_id]

is_research_csv = CSV.open(File.join('is_research.csv'), 'w+')
is_research_errors_csv = CSV.open(File.join('is_research_errors.csv'), 'w+')

iterations = 0

processed_bibs = [].to_set

while true
  puts "from_item_id: #{from_item_id}"
  puts "iterations: #{iterations}"

  conn = PG.connect( host: 'localhost', dbname: 'itemservice', user: 'itemservice')

  results = conn.exec(
    "select id, location, fixed_fields, bib_ids from item " +
    "where nypl_source='sierra-nypl' and deleted is FALSE and " +
    "id > '#{from_item_id}' " +
    "order by id limit #{params[environment][:limit]}"
  )

  ids = results.field_values 'id'

  if ids.empty?
    puts "Got through the items!"
    break
  end

  conn.close

  results.each do |item|
    begin
      raise DataError.new("This item record is missing the `bib_ids` property") unless item["bib_ids"]

      bib_ids = JSON.parse item["bib_ids"]

      if bib_ids.any?
        raise DataError.new("This item record is missing the `fixed_fields` property") unless item["fixed_fields"]
        raise DataError.new("This item record is missing the `location` property") unless item["location"]

        location = JSON.parse item["location"]
        fixed_fields = JSON.parse item["fixed_fields"]

        item_data = {
          nypl_source: "sierra-nypl",
          id: item["id"],
          item_type_code: fixed_fields["61"]["value"],
          location_code: location["code"],
        }

        bib_ids.each do |bib_id|
          if !processed_bibs.include?(bib_id)
            result = is_research?(bib_id, item_data)
            processed_bibs << bib_id
            is_research_csv << [bib_id, result]
          end
        end
      end
    rescue => e
      puts item["id"], e
      is_research_errors_csv << [item["id"], e]
    end
  end

  iterations += 1

  from_item_id = ids.last
end
