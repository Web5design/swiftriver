class Tag < ActiveRecord::Base
  has_many :report_tags, :dependent => :destroy
  has_many :reports, :through => :report_tags
  
  TAG_SEPARATOR = "\001"
  def to_s
    self.description
  end
  def self.parse_tags(string)  
    string.split(/"(.+?)"|\s+/).reject {|s| s.empty? }.map {|s| s.chomp(",")}
  end    
  def self.listing
    Tag.find(:all, :order => 'pattern DESC')
  end

  def self.aggregate_history
    Reporter.find :all,   :select => "count(id), concat(hour(created_at),':',minute(created_at)) as time", :group => "hour(created_at), minute(created_at)" 
  end
  
    
end