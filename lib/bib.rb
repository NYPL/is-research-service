require 'httparty'

class Bib < MarcRecord
  def is_research?
    begin
      items = get_platform_api_data items_path
      result = is_partner? || is_mixed_bib? || first_item_is_research?(items)
    rescue NotFoundError => e
      bib = get_platform_api_data bib_path
      raise DeletedError if bib["deleted"]
      result = !!bib
    end

    $logger.debug "Evaluating is-research for bib #{nypl_source} #{id}: #{result}", @log_data

    result
  end

  private
  def is_mixed_bib?
    if @@mixed_bib_ids.nil?
      @@mixed_bib_ids = File.read('data/mixed-bibs.csv')
        .split("\n")
        .map { |bnum| bnum.strip.sub(/^b/, '') }

      $logger.debug "Loaded #{@@mixed_bib_ids.size} mixed bib ids"
    end

    is_mixed_bib = @@mixed_bib_ids.include? bib['id']
    $logger.debug "Determined is_mixed_bib=#{is_mixed_bib} for #{bib['id']}"

    is_mixed_bib
  end

  def first_item_is_research?(items)
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
