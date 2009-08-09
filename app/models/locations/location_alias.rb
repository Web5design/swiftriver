class LocationAlias < ActiveRecord::Base
  
  belongs_to :location
  
  # Finds the Location alias, either by specifying a location = {"latitude"=>, "longitude"=>}, or in the location_text
  def self.locate(location_text, location = [])
    location_alias = LocationAlias.find_by_text(location_text)
    return location_alias.location if location_alias
    unless location.blank?
      point = Point.from_x_y(location["longitude"].to_f, location["latitude"].to_f)
      loc = {:address => location_text, :point => point}
      db_location = Location.find_by_point(loc[:point]) || Location.create(loc)
      create(:text => location_text, :location_id => db_location.id)
      db_location
    
    else
      unless loc = Geo::Geocoder.geocode(location_text)

        InvalidLocation.create(:text => location_text) rescue nil
        return nil
      end
      db_location = Location.find_by_point(loc[:point]) || Location.create(loc)
      create(:text => location_text, :location_id => db_location.id)
      db_location
    end
  end
  
end
