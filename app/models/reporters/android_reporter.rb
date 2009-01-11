class AndroidReporter < Reporter
  before_create :set_location
  validates_format_of :uniqueid, :with => /^\d{14,16}/, :on => :create, :message => "Invalid IMEI"
    
  def source_name; "#{APP_NAME} Android App"; end
  def icon; "/images/iphone_icon.png"; end
  def audio_filetype; "mp3"; end
  def photo_filetype; "jpg"; end
  
  private
  def set_location
    self.latlon, location_accuracy = self.latlon.split(':')
    if self.location = Location.geocode(self.latlon)
      self.profile_location = self.location.address if self.profile_location.nil?
    end
  end
end