class FeedReporter < Reporter

  def source_name; "Feed"; end
  def source; "Feed"; end
  def icon; "/images/youtube_icon.png"; end
  def display_name; name || screen_name; end
end
