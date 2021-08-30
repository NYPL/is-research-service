require "pry"
require 'nypl_log_formatter'
require "json"
require 'pg'
require 'csv'
require 'set'
require './lib/item.rb'
require './lib/nypl_core.rb'
require './lib/errors.rb'

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

  conn = PG.connect( host: ENV['DB_HOST'], dbname: ENV['DB_NAME'], user: ENV['USER'], password: ENV['PASSWORD'])

  results = conn.exec(
    "select id, nypl_source, location, fixed_fields, bib_ids from item " +
    "where deleted is FALSE and id > '#{from_item_id}' " +
    "order by id limit #{params[environment][:limit]}"
  )

  ids = results.field_values 'id'

  if ids.empty?
    puts "Got through the items!"
    break
  end

  conn.close

  results.each do |db_record|
    next unless db_record['nypl_source'] == 'sierra-nypl'

    begin
      raise DataError.new("This item record is missing the `bib_ids` property") unless db_record["bib_ids"]

      bib_ids = JSON.parse db_record["bib_ids"]

      if bib_ids.any? { |id| !processed_bibs.include?(id) }
        raise DataError.new("`fixed_fields` property missing") unless db_record["fixed_fields"]
        raise DataError.new("`location` property missing") unless db_record["location"]

        id = db_record['id']
        nypl_source = db_record['nypl_source']
        location = JSON.parse db_record["location"]
        fixed_fields = JSON.parse db_record["fixed_fields"]

        item = Item.new(nypl_source, id)

        bib_ids.each do |bib_id|
          if !processed_bibs.include?(bib_id)
            is_research_csv << [bib_id, item.is_research?(data={'fixedFields' => fixed_fields, 'location' => location})]
            processed_bibs << bib_id
          end
        end
      end
    rescue => e
      puts db_record["id"], e
      is_research_errors_csv << [db_record["id"], e]
    end
  end

  iterations += 1

  from_item_id = ids.last
end
