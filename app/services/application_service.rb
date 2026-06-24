class ApplicationService
  def self.call(...)
    new(...).call
  end

  private

  def success(data)
    OpenStruct.new(success?: true, data: data, errors: [])
  end

  def failure(errors)
    OpenStruct.new(success?: false, data: nil,
                   errors: Array(errors))
  end
end