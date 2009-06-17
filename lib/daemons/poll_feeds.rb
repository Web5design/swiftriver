# Simple Feed Polling daemon
# (C) 2009 Andrew Turner, andrew@highearthorbit.com

#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= defined?(Daemons) ? 'production' : 'development'

require File.dirname(__FILE__) + "/../../config/environment"
%w{ rubygems rfeedparser }.each {|gem| require gem}

class FeedPoller
  POLL_INTERVAL = 30

  def initialize(feeds)
    @feeds = feeds
    @feeds.each do |feed_id, feed|
      u_attrs = { 'uniqueid' => feed_id,
        'screen_name' => feed_id,
        'name' => feed['name']}
      case feed["type"]
      when /news/
        @feeds[feed_id]["reporter"] = NewsReporter.update_or_create(u_attrs)
      when /youtube/
        @feeds[feed_id]["reporter"] = YoutubeReporter.update_or_create(u_attrs)
      when /twitter/
        @feeds[feed_id]["reporter"] = TwitterReporter.update_or_create(u_attrs)
      end
    end
    @running = true
    Signal.trap("TERM") { @running = false }
    poll
  end

  def poll
    while (@running) do
      @feeds.each do |feed_id, feed_config|
        feed = FeedParser.parse(feed_config["url"])
        puts "#{feed.title} = #{feed_config["url"]}"
        feed.entries.each do |e|
	body = e.content.nil? ? "" : e.content.first["value"]
            feed_config["reporter"].reports.create({ 'title' => e.title,
                    'body' => body,
                    'uniqueid' => e.guid,
                    'created_at' => e.published,
                    'link_url' => e.link }) 
                    puts e.title
        # rescue
        #   next
        end
      end
      sleep POLL_INTERVAL
    end
  end
  
end
feeds = YAML.load(open(File.dirname(__FILE__) + "/../../config/feeds.yml"))
FeedPoller.new(feeds)

