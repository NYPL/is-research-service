require 'httparty'
require_relative 'marc_record'

class Item < MarcRecord
  attr_accessor :item_type_code, :location_code

  def is_research?(data=get_platform_api_data(item_path))
    validate_record(data)

    if is_partner?
      result = true
    else
      set_properties(data)
      result = item_type_is_research? || location_is_only_research?
    end

    $logger.debug "Evaluating is-research for item #{nypl_source} #{id}: #{result}", @log_data

    return result
  end

  def validate_record(data)
    raise DataError("Record has no fixedFields property") unless data["fixedFields"]
    raise DataError("Record does not have fixedFields 61") unless data["fixedFields"]["61"]
    raise DataError("Record does not have a value property on fixedFields 61") unless data["fixedFields"]["61"]["value"]
    raise DataError("Record does not have a location property") unless data["location"]
    raise DataError("Record does not have a code for location property") unless data["location"]["code"]
  end

  private
  def item_path
    "items/" + @nypl_source + "/" + @id
  end

  def item_type_is_research?
    item_collection_type = $nypl_core.by_catalog_item_type[item_type_code]
    if item_collection_type.nil?
      $logger.error "Unknown item_type #{item_type_code}"
      raise DataError.new("This item's catalog item type [#{item_type_code}] is not reflected in NYPL Core")
    end
    result = item_collection_type["collectionType"].include?("Research")
    @log_data[:item_type_is_research?] = result
    return result
  end

  def location_is_only_research?
    sierra_location = $nypl_core.by_sierra_location[location_code]
    if sierra_location.nil?
      $logger.error "Unknown location_code #{location_code}"
      raise DataError.new("This item's Sierra location code [#{location_code}] is not reflected in NYPL Core")
    end
    collection_types = sierra_location["collectionTypes"]
    result = collection_types == ["Research"]
    @log_data[:location_is_only_research] = result
    return result
  end

  def set_properties(data)
    self.item_type_code = data["fixedFields"]["61"]["value"]
    self.location_code = data["location"]["code"]
  end
end
