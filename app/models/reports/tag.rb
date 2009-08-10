class Tag < ActiveRecord::Base
  has_many :report_tags, :dependent => :destroy
  has_many :reports, :through => :report_tags
  
  def to_s
    self.description
  end
  def self.parse_tags(string)  
    string.split(/"(.+?)"|\s+/).reject {|s| s.empty? }.map {|s| s.chomp(",")}
  end    
  def self.listing
    Tag.find(:all, :order => 'pattern DESC')
  end
end