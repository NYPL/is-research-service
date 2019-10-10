require 'httparty'

class Item
  attr_reader :nypl_source, :id
  attr_accessor :item_type_code, :location_code


  def initialize(nypl_source, id)
    @nypl_source = nypl_source
    @id = id
    @log_data = {}
  end

  def is_research?
    get_platform_api_data

    result = is_partner? || item_type_is_research? || location_is_only_research?

    $logger.debug "Evaluating is-research for #{nypl_source} #{id}: #{result}", @log_data

    return result
  end

  private
  def is_partner?
    result = nypl_source == "recap-cul" || nypl_source == "recap-pul"
    @log_data[:is_partner?] = result
    return result
  end

  def item_type_is_research?
    item_collection_type = $nypl_core.by_catalog_item_type[item_type_code]
    if item_collection_type.nil?
      $logger.debug "Unknown item_type #{item_type_code}"
      raise DataError.new("This item's catalog item type is not reflected in NYPL Core")
    end
    result = item_collection_type["collectionType"].include?("Research")
    @log_data[:item_type_is_research?] = result
    return result
  end

  def location_is_only_research?
    sierra_location = $nypl_core.by_sierra_location[location_code]
    if sierra_location.nil?
      $logger.debug "Unknown location_code #{location_code}"
      raise DataError.new("This item's Sierra location is not reflected in NYPL Core")
    end
    collection_types = sierra_location["collectionTypes"]
    result = collection_types == ["Research"]
    @log_data[:location_is_only_research] = result
    return result
  end

  def get_platform_api_data
    response = $platform_api.get("items/" + @nypl_source + "/" + @id)

    raise NotFoundError unless response["data"]

    data = response["data"]

    return if is_partner?

    raise DataError("Record has no fixedFields property") unless data["fixedFields"]
    raise DataError("Record does not have fixedFields 61") unless data["fixedFields"]["61"]
    raise DataError("Record does not have a value property on fixedFields 61") unless data["fixedFields"]["61"]["value"]
    raise DataError("Record does not have a location property") unless data["location"]
    raise DataError("Record does not have a code for location property") unless data["location"]["code"]

    self.item_type_code = data["fixedFields"]["61"]["value"]
    self.location_code = data["location"]["code"]
  end
end
