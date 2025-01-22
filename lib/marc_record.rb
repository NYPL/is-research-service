require_relative 'platform_api_client'
require_relative 'nypl_core'

class MarcRecord
  attr_reader :nypl_source, :id

  def initialize(nypl_source, id)
    @nypl_source = nypl_source
    @id = id
    @log_data = {}
  end

  def is_partner?
    result = /^recap-/.match? nypl_source
    @log_data[:is_partner?] = result
    return result
  end

  def get_platform_api_data(api_path)
    response = $platform_api.get(api_path)

    raise NotFoundError unless response["data"]

    response["data"]
  end

  def is_tagged_as_research?(data)
    if data["varFields"] == nil
      return false
    end
    data["varFields"].each do |field|
      if field["marcTag"] == "910" and field["subfields"] != nil
        field["subfields"].each do |subfield|
          if subfield["tag"] == "a" and (subfield["content"] == "RL" or subfield["content"] == "RLOTF")
            return true
          end
        end
      end
    end
    return false
  end
end
