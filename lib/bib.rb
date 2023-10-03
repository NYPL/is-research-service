require_relative 'marc_record'
require_relative 'errors'
require_relative 'item'

class Bib < MarcRecord
  def is_research?
    result = false
    begin
      result = is_partner? || first_item_is_research?
    rescue NotFoundError => e
      bib = get_platform_api_data bib_path
      raise DeletedError if bib["deleted"]
      # Only a research bib would exist with no items
      result = true
    end

    $logger.debug "Evaluating is-research for bib #{nypl_source} #{id}: #{result}", @log_data

    result
  end

  private

  def first_item_is_research?
    items = get_platform_api_data items_path
    item_record = items[0]

    item = Item.new(item_record["nyplSource"], item_record["id"])
    result = item.is_research?(item_record)

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
