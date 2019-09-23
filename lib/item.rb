require 'httparty'
require "pry"

class Item
  attr_reader :nypl_source, :id
  attr_accessor :item_type, :location

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

    end

    def location_is_research
      collection_types = $nypl_core.by_sierra_location[location_type]["collectionTypes"]
      return collection_types.length == 1 && collectionTypes[0] == "Research"
    end

    def get_item_type_and_location_type
      data = HTTParty.get('https://platform.nypl.org/api/v0.1/items/' + nypl_source + "/" + id, headers: {
        "authorization" => auth
        }
      )["data"]
      item_type = data["fixedFields"]["61"]["value"]
      location = data["location"]["code"]
    end
end

# sierra = 'sierra-nypl'
# pul = 'recap-pul'
#
# item = Item.new(pul, "17746307")
#
# puts item.is_research
