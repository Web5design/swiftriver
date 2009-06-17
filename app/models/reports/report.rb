class Report < ActiveRecord::Base
#	acts_as_solr
	
  validates_presence_of :reporter_id
  validates_uniqueness_of :uniqueid, :scope => :source, :allow_blank => true, :message => 'already processed'
  
  # Virtual fields provided by some reporters
  attr_accessor :latlon, :location_name
  
  belongs_to :location
  belongs_to :reporter
  belongs_to :reviewer, :class_name => "User"
  
  has_many :report_tags, :dependent => :destroy
  has_many :tags, :through => :report_tags
  has_many :report_filters, :dependent => :destroy
  has_many :filters, :through => :report_filters

  before_validation :set_source
  before_create :block_banned, :detect_location
  # check_uniqueid must be AFTER create because otherwise it doesn't have an ID
  after_create :check_uniqueid, :assign_filters, :auto_review
  before_save { |record| record.location_id = record.reporter.location_id if record.location_id.nil? }
  
  named_scope :with_location, :conditions => 'reports.location_id IS NOT NULL'
  named_scope :with_score, :conditions => 'reports.score IS NOT NULL'
  named_scope :assigned, lambda { |user| 
    { :conditions => ['reviewer_id = ? AND reviewed_at IS NULL AND assigned_at > UTC_TIMESTAMP - INTERVAL 10 MINUTE', user.id],
      :order => 'reports.created_at DESC' }
  }
  # @reports = Report.unassigned.assign(@current_user) &tc...
  named_scope( :unassigned, lambda { |options|
    options ||= {}
    unreviewed = 'reviewed_at IS NULL AND (reviewer_id IS NULL OR assigned_at < UTC_TIMESTAMP - INTERVAL 10 MINUTE)'
    options.include?(:conditions) ? options[:conditions][0] << " AND #{unreviewed}" : options[:conditions] = unreviewed
    
    { :limit => 1, 
     :order => 'reports.created_at DESC' }.merge(options)
  }) do
    def assign(reviewer)
      # FIXME: can't we do this more efficiently? a la p-code:
      # self.update_all(reviewer_id=reviewer.id, assigned_at => time.now where id IN (each.collect{r.id}))
      each { |r| r.update_attributes(:reviewer_id => reviewer.id, :assigned_at => Time.now.utc) }
    end
  end

  cattr_accessor :public_fields
  @@public_fields = [:id,:body,:score,:created_at,:updated_at]

  def tag_list
    self.tags.join(" ")
  end
  def tag_list=(tags)
    self.tags = tags
  end


  alias_method :ar_tags=, :tags=
  def tags=(tags)
    tag_objects = tags.collect do |tag|
      tag.is_a?(Tag) ? tag : Tag.find_or_create_by_description(tag)
    end
    self.ar_tags = tag_objects
  end
  
  def name
    self.reporter.name
  end
  
  def dismiss!(user=nil)
    self.dismissed_at = Time.now.utc
    self.reviewer = user if user
    self.reviewed_at = Time.now.utc
    user.update_reports_count! if user
    self.save_with_validation(false)
  end
  
  def confirm!(user=nil)
    self.dismissed_at = nil
    self.reviewer = user if user
    self.reviewed_at = Time.now.utc
    if self.save
      user.update_reports_count! if user
      return true
    else
      return false
    end
  end
  
  def is_confirmed?
    self.dismissed_at.nil? && !self.reviewed_at.nil?
  end
  
  def is_dismissed?
    !self.dismissed_at.nil?
  end
  
  def icon
    self.reporter.icon =~ /http:/ ? self.reporter.icon : "#{SERVER_URL}#{self.reporter.icon}"
  end
    
  alias_method :ar_to_json, :to_json
  def to_json(options = {})
    options[:only] = @@public_fields
    # options[:include] = [ :reporter ]
    # options[:except] = [ ]
    options[:methods] = [ :media_url, :class, :display_text, :display_html, :score, :name, :icon, :reporter, :location ].concat(options[:methods]||[]) 
    # options[:additional] = {:page => options[:page] }
    # ar_to_json(options)
    (options[:only] + options[:methods]).inject({}) {|result,field| result[field] = self.send(field); result }.to_json
  end    

  def media_url
    "#{self.url}" if self.respond_to?(:url)
  end
  
  # Primary method to get reports with any of the following filters:
  # :q - generic search query term
  # :dtstart, :dtend - Time span begin and end to search
  # :type - report type (video, audio, photo, text)
  # :name - reporter name
  # :state - two-letter code for state (e.g. NY, DC, PA)
  def self.find_with_filters(filters = {})
    # If we're searching a join table (filters, reporters) do a recursive search
    if filters.include?(:country) && !filters[:country].blank?
      filtered = Location.find_by_country_code(filters.delete(:country))
      return filtered.reports.find_with_filters(filters) if filtered
    elsif filters.include?(:state) && !filters[:state].blank?
      filtered = Filter.find_by_name(US_STATES[filters.delete(:state)])
      return filtered.reports.find_with_filters(filters) if filtered
    elsif filters.include?(:name) && !filters[:name].blank?
      reporter = Reporter.find_by_screen_name(filters.delete(:name))
      return reporter.reports.find_with_filters(filters) if reporter
    end
    
    where = "1=1"
    if filters.include?(:dtstart) && !filters[:dtstart].blank?
      where << " AND created_at >= :dtstart "
    end
    # filters[:dtend] = '2009-1-27' if filters[:dtend].blank?
    if filters.include?(:dtend) && !filters[:dtend].blank?
      where << " AND created_at <= :dtend "
    end
    if filters.include?(:score) && !filters[:score].blank?
      where << " AND score IS NOT NULL AND score <= :score"
    end
    if filters.include?(:type) && !filters[:type].blank?
      filters[:type] = "#{filters[:type].capitalize}Report" unless filters[:type].match(/Report/)
      where << " AND type = :type "
    end
    if filters.include?(:q) && !filters[:q].blank?
      where << " AND body LIKE :q "
      filters[:q] = "%#{filters[:q]}%"
    end
    if filters.include?(:reporter) && !filters[:reporter].blank?
      where << " AND reporter.type = :reporter "
      filters[:q] = "%#{filters[:reporter]}%"
    end
  
    Report.paginate( :page => filters[:page] || 1, :per_page => filters[:per_page] || 10, 
      :order => 'reports.created_at DESC',
      :conditions => [where,filters],
      :include => [:location, :reporter])
  end

  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  
  # Yes, we know all this view code should not be in here; move along
  def media_link
    case self.class.name
    when /AudioReport/
      return "<embed src='#{self.url}' width='100' height='20' AUTOPLAY='false'/>"
    when /PhotoReport/
      self.link_url ? "<a href='#{self.link_url}' class='imageLink' target='new'><img src='#{self.url}' width='180'/></a>" :
        "<a href='#{self.large_url}' class='imageLink' target='new'><img src='#{self.url}' width='180'/></a>"
    when /VideoReport/
      self.link_url ? "<a href='#{self.link_url}' class='imageLink' target='new'><img src='#{self.url}' width='180'/></a>" : "<img src='#{self.url}' width='180'/>"
    else
      return ""
    end
  end
  
  # Formatted report body text
  def display_text
    auto_link_urls(self.body || "", :target => '_new') { |linktext| truncate(linktext, :length => 30) }
  end
  
  def display_html
    html = '<div class="balloon">'

    if self.reporter.class == TwitterReporter
      html << %Q{<a href="#{self.reporter.profile}"><img src=#{self.reporter.icon} class="profile" target="_new"/></a>}
    else
      html << %Q{<br /><img src="#{self.reporter.icon}" class="profile" />}
    end
    html << %Q{<div class="balloon_body"><span class="author" id="screen_name">#{self.reporter.display_name}</span>: }
    linked_text = auto_link_urls(self.body || "", :target => '_new') { |linktext| truncate(linktext, :length => 30) }
    html << %Q{<span class="entry-title">#{linked_text}</span><br />}
    html << self.media_link

    html << "<br /><div class='whenwhere'>"
    if self.reporter.is_a?(TwitterReporter)
      html << %Q{reported <a href="http://twitter.com/#{self.reporter.screen_name}/statuses/#{self.uniqueid}">#{ time_ago_in_words(self.created_at)} ago</a> }
    else
      html << "reported #{time_ago_in_words(self.created_at)} ago"
    end
    html << "<br />from #{self.location.address.gsub(/, USA/,'')}"
    html << "<br />via #{self.reporter.source_name}</div></div></div>"

    html
  end

  def self.hourly_usage
    ActiveRecord::Base.connection.select_all(%Q{select count(*) as count, HOUR(created_at)-4 as hour from reports WHERE created_at > "2008-11-04" group by HOUR(created_at)})    
  end
  
  private

  # Populate a uniqueid if not supplied by the reporting mechanism
  def check_uniqueid
    update_attribute(:uniqueid, "#{Time.now.to_i}.#{self.id}") if self.uniqueid.nil?
    true
  end
  
  def set_source
    self.source=reporter.source
    true
  end
  
  # Detect and geocode any location information present in the report
  def detect_location
    return true if self.location_id
    if self.latlon
      ll, self.location_accuracy = self.latlon.split(/:/)
      ll.gsub!(/ /,'')
      self.location = Location.geocode(ll)
    elsif self.location_name
      self.location = Location.geocode(location_name)
    elsif self.body
      LOCATION_PATTERNS.find { |p| self.body[p] } 
      self.location = Location.geocode($1) if $1
    end
    unless self.location
      locations = Location.find(:all).inject({}){|a,l| a[l.locality] = a}
      localities = locations.collect{|name,l| body.scan(name).length > 0 ? l : nil unless name.blank?}.compact
      self.location = localities.first
    end
    self.reporter.update_attributes(:location_id => self.location_id) if self.location
    self.location ? true : false
  end
    
  # What location filters apply to this report?  US, MD, etc?
  def assign_filters
    unless self.body.blank?
      begin
      calais = Calais.process_document(:content => self.body, 
        :content_type => :text, :license_id => CALAIS_LICENSE)
      self.location = Location.geocode(calais.geographies.first.name, calais.geographies.first) unless calais.geographies.blank?
    rescue Exception => e
      logger.error "Error parsing report with OpenCalais: #{e.message}"
    end
    end
    if self.location_id && self.location.filter_list
			values = self.location.filter_list.split(',').map { |f| "(#{f},#{self.id})" }.join(',')
      self.connection.execute("INSERT DELAYED INTO report_filters (filter_id,report_id) VALUES #{values}") if !values.blank?
		end
		
		true
  end
  
  def auto_review
    # TODO: this should approve things that fall within kosher-seeming params
    true
  end
  
  def block_banned
    !reporter.blocked?
  end
end
