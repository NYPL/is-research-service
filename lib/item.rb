require 'httparty'
require "pry"

class Item
  attr_reader :nypl_source, :id
  attr_accessor :item_type_code, :location_code

  def initialize(nypl_source, id) # will come from URL
    @nypl_source = nypl_source
    @id = id
  end

  def is_research
    return true if is_partner

    get_item_type_and_location_type

    item_type_is_research || location_is_research
  end

  private
    def is_partner
      nypl_source == "recap-cul" || nypl_source == "recap-pul"
    end

    def item_type_is_research
      item_collection_type = $nypl_core.by_catalog_item_type[item_type_code]
      return item_collection_type["collectionType"][0] == "Research"
    end

    def location_is_research
      collection_types = $nypl_core.by_sierra_location[location_code]["collectionTypes"]
      return collection_types.length == 1 && collection_types[0] == "Research"
    end

    def get_item_type_and_location_type
      puts @nypl_source
      puts @id
      response = $platform_api.get("items/" + @nypl_source + "/" + @id)

      raise "Invalid identifiers" if response.nil? || response["data"].nil?

      data = response["data"]
      self.item_type_code = data["fixedFields"]["61"]["value"]
      self.location_code = data["location"]["code"]
    end
end
