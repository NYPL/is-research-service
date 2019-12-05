def item_type_is_research?(item_type_code)
  item_collection_type = $nypl_core.by_catalog_item_type[item_type_code]
  if item_collection_type.nil?
    $logger.error "Unknown item_type #{item_type_code}"
    raise DataError.new("This item's catalog item type [#{item_type_code}] is not reflected in NYPL Core")
  end
  result = item_collection_type["collectionType"].include?("Research")
  @log_data[:item_type_is_research?] = result
  return result
end

def location_is_only_research?(location_code)
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

def is_research?(data)
  result = item_type_is_research?(data[:item_type_code]) || location_is_only_research?(data[:location_code])
  $logger.debug "Evaluating is-research for item #{data[:nypl_source]} #{data[:id]}: #{result}", @log_data
  return result
end

def is_mixed_bib?(id)
  if $mixed_bib_ids.nil?
    $mixed_bib_ids = File.read('data/mixed-bibs.csv')
    .split("\n")
    .map { |bnum| bnum.strip.sub(/^b/, '').chop }

    $logger.debug "Loaded #{$mixed_bib_ids.size} mixed bib ids"
  end

  is_mixed_bib = $mixed_bib_ids.include? id
  $logger.debug "Determined is_mixed_bib=#{is_mixed_bib} for #{id}"

  is_mixed_bib
end
