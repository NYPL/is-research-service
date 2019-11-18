require 'httparty'

class Bib < MarcRecord
  def is_research?
    data = get_platform_api_data

    result = @is_partner || has_zero_items?(data) || has_at_least_one_research_item?(data)

    $logger.debug "Evaluating is-research for #{nypl_source} #{id}: #{result}", @log_data

    return result
  end

  private
  def has_zero_items?(data)
    data.length == 0
  end

  def has_at_least_one_research_item?(data)
    return !!data.find { |item|
      item = Item.new(item["nyplSource"], item["id"])
      item.is_research?
    }
  end

  def api_path
    "bibs/" + @nypl_source + "/" + @id + "/items"
  end
end
