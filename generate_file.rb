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
is_research_file = "bibs_is_research.json"

def init
  return if $initialized

  $nypl_core = NyplCore.new
  $logger = NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'] || 'info')
  $platform_api = PlatformApiClient.new

  $initialized = true
end

init

bibs = {}

# done_bibs = File.read(is_research_file)
#
# bibs = JSON.parse(done_bibs)

File.readlines(bibs_file).each do |line|
  begin
    id = line.strip
    bib = Bib.new("sierra-nypl", id)
    is_research = bib.is_research?
    bibs[id] = {"research" => is_research}
  rescue => e
    puts e, id
  end
  File.open("bibs_is_research.json", "w+") do |f|
    f.write(JSON.pretty_generate(bibs))
  end
end

# CSV.foreach(is_research_file, 'r') do |line|
#   print line
# end

# CSV.open(is_research_file, "w+") do |csv|
#
#   File.readlines(file).each do |line|
#     id = line.strip
#     bib = Bib.new("sierra-nypl", id)
#     is_research = bib.is_research?
#     csv << [line.strip, is_research]
#     puts "Bib #{id}, research: #{is_research}"
#   end
# end
