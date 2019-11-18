require 'httparty'

class Bib < MarcRecord
  def is_research?
    items = get_platform_api_data items_path

    result = is_partner? || has_zero_items?(items) || has_at_least_one_research_item?(items)

    $logger.debug "Evaluating is-research for bib #{nypl_source} #{id}: #{result}", @log_data

    return result
  end

  private
  def has_zero_items?(items)
    result = items.empty?
    @log_data[:has_zero_items?] = result
    result
  end

  def has_at_least_one_research_item?(items)
    result =  !!items.find { |item|
      item = Item.new(item["nyplSource"], item["id"])
      item.is_research?
    }
    @log_data[:has_at_least_one_research_item?] = result
    result
  end

  def items_path
    "bibs/" + @nypl_source + "/" + @id + "/items"
  end
end
