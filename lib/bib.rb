require 'httparty'

class Bib < MarcRecord
  def is_research?
    begin
      items = get_platform_api_data items_path
    rescue NotFoundError => e
      bib = get_platform_api_data bib_path
    end
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
    result =  !!items.find { |item_record|
      item = Item.new(item_record["nyplSource"], item_record["id"])
      item.is_research?(item_record)
    }
    @log_data[:has_at_least_one_research_item?] = result
    result
  end

  def bib_path
    "bibs/" + @nypl_source + "/" + @id
  end

  def items_path
    bib_path + "/items"
  end
end
