class CreateReports < ActiveRecord::Migration
  def self.up
    create_table "reports" do |t|
      t.integer  "location_id"
      t.string   "text"
      t.integer  "score"
      t.string   "callerid",       :limit => 20
      t.string   "uniqueid",       :limit => 20
      t.string   "zip",            :limit => 5
      t.integer  "input_source_id"
      t.integer  "tid"                                # Twitter internal ID
      t.integer  "twitter_user_id"
      t.timestamps
    end

    add_index "reports", ["tid"], :name => "index_reports_on_tid", :unique => true

    create_table "twitter_users" do |t|
      t.integer "tid"                                 # Twitter internal ID
      t.string  "name", :limit => 80
      t.string  "screen_name", :limit => 80
      t.string  "profile_location", :limit => 200
      t.string  "profile_image_url", :limit => 200
      t.integer "followers_count"
      t.integer "location_id"
      t.timestamps
    end
    
    add_index "twitter_users", ["tid"], :name => "index_twitter_users_on_tid", :unique => true
    
    create_table "report_tags" do |t|
      t.integer "report_id"
      t.integer "tag_id"
    end

    create_table "tags" do |t|
      t.string "pattern", :limit => 30
      t.string "description", :limit => 80
      t.integer "score"
    end
    
    
    # Location-related tables
    create_table "location_aliases", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "text", :string, :limit => 80
      t.column "location_id", :integer
    end

    add_index "location_aliases", ["text"], :name => "index_location_aliases_on_text", :unique => true
    add_index "location_aliases", ["location_id"], :name => "index_location_aliases_on_location_id"

    create_table "locations", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "address", :string
      t.column "country_code", :string, :limit => 10
      t.column "administrative_area", :string, :limit => 80
      t.column "sub_administrative_area", :string, :limit => 80
      t.column "locality", :string, :limit => 80
      t.column "thoroughfare", :string, :limit => 80
      t.column "postal_code", :string, :limit => 25
      t.column "point", :point, :null => false
      t.column "geo_source_id", :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "filter_list", :string
    end

    add_index "locations", ["point"], :name => "index_locations_on_point", :spatial=> true

    create_table "filters", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "name", :string, :limit => 80
      t.column "aliases", :string
      t.column "title", :string, :limit => 80
      t.column "center_location_id", :integer
      t.column "radius", :integer
      t.column "conditions", :text
      t.column "zoom_level", :integer
      t.column "state", :string, :limit => 2
      t.column "country_code", :string, :limit => 2
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "invalid_locations", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "text", :string, :limit => 80
      t.column "unknown", :boolean
    end

    add_index "invalid_locations", ["text"], :name => "index_invalid_locations_on_text", :unique => true

  end

  def self.down
    drop_table :reports
    drop_table :twitter_users
    drop_table :report_tags
    drop_table :tags
    drop_table :location_aliases
    drop_table :locations
    drop_table :filters
    drop_table :invalid_locations
  end
end