class Select2LocationsService
  def initialize(term)
    @term = term
  end

  def perform
    query = I18n.available_locales.map do |locale|
      "location.`name_#{locale}` =~ '(?i).*#{@term}.*'"
    end.join(' OR ')
    results = Location.query_as(:location)
                      .where(query)
                      .pluck(:location)
    results.map do |location|
      { id: location.id, text: location.name_with_address }
    end
  end
end
