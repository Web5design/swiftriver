class NewsReporter < Reporter

  def source_name; "News"; end
  def source; "News"; end
  def icon; "/images/youtube_icon.png"; end
  def display_name; name || screen_name; end
end
