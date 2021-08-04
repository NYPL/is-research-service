require 'open-uri'

class NyplCore
  def initialize
    @mappings = {}
    by_mapping('by_sierra_location.json')
    by_mapping('by_catalog_item_type.json')
  end

  def check_sierra_location(location_code)
    @mappings['by_sierra_location.json'][location_code]
  end

  def check_catalog_item_type(item_type_code)
    @mappings['by_catalog_item_type.json'][item_type_code]
  end

  private
  def by_mapping(mapping_file)
    @mappings[mapping_file] = JSON.parse(URI.open(ENV['NYPL_CORE_S3_BASE_URL'] + mapping_file).read) if @mappings[mapping_file].nil?
    @mappings[mapping_file]
  end
end
