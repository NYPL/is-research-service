class ParameterError < StandardError
  def initialize(msg="Parameter error")
    super
  end
end

class DataError < StandardError
  def initialize(msg="DataError")
    super
  end
end
