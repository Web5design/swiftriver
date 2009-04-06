ENV["RAILS_ENV"] ||= defined?(Daemons) ? 'production' : 'development'

# FIXME: pull in the platform.yml for the tag(s)
# FEED = "http://twittervision.com/inaugreport.json"
EXTRACTOR = Regexp.new(/^(\w+?):\s(.*)$/m)

require File.dirname(__FILE__) + "/../../config/environment"
require 'json'
require 'open-uri'
require 'twitterchive'

platform = YAML.load(open(File.dirname(__FILE__) + "/../../config/platform.yml"))

$running = true
Signal.trap("TERM") do 
  $running = false
end

while($running) do
  # tweets = JSON.parse(open(FEED).read)
  tags = platform[ENV["RAILS_ENV"]]["tags"].gsub(/,/," OR ")
  tag_archive = Twitterchive.new(tags)
  tag_archive.fetch
  puts "Processing #{tag_archive.entries.length} entries"
  tag_archive.entries.each do |entry|
    user_info = {} #entry['source']['author']
    user_info["uniqueid"],user_info["name"] = entry["author/name"].match(/(.*) \((.*)\)/)[1,2]
    
    # {'twitter_id' => 'uniqueid', 'location' => 'profile_location'}.each do |k,v|
    #   user_info[v] = user_info.delete(k)
    # end
    next unless reporter = TwitterReporter.update_or_create(user_info)

    # screen_name, text = entry['title'].match(TwitterReporter::EXTRACTOR).captures
    puts ":uniqueid =>#{ entry['id']}"
    reporter.text_reports.create(:body => entry['title'],
                        :uniqueid => entry['id'][/:(\d+)/].gsub(/:/,''),
                        :created_at => entry['published'])
  end
  sleep 10
end

