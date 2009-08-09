require File.dirname(__FILE__) + '/../test_helper'

class ReporterTest < ActiveSupport::TestCase
  def test_twitter_reporter_creation
    reporter = TwitterReporter.create(:uniqueid => 1234, :name => "Bob", :screen_name => 'nitro', :followers_count => 3, :profile_location => '90210')
    assert_equal 3, reporter.followers_count
    assert_equal "Twitter", reporter.source_name
    assert_equal "Beverly Hills, CA 90210, USA", reporter.location.address
    assert_equal "TwitterReporter", reporter.type
    report = reporter.reports.create(:uniqueid => '29292929', :body => 'chilling in l:80303')
    assert_equal 1, reporter.reports.size
    assert_equal "Boulder, CO 80303, USA", report.location.address
  end

  def test_android_reporter_creation
    reporter = AndroidReporter.create(:uniqueid => '8282737364648989', :name => "Bob Android") #, :latlon => '43.024,-76.411:1400'
    assert_match /Elbridge/, reporter.profile_location
    assert_nil reporter.followers_count
    assert_equal "VoteReport Android App", reporter.source_name
    report = reporter.reports.create(:uniqueid => nil, :body => 'all is well in l:Birmingham, AL', :score => '78', :latlon => '39.024,-76.511:2192')
    assert_equal 1, reporter.reports.size
    assert_equal "Birmingham, AL, USA", report.location.address
    assert_equal 78, report.score
    assert_equal 0, report.tags.size
    assert report.uniqueid.ends_with?(report.id)
    # assert_equal 1400, report.location_accuracy
  end
  
  def test_sms_reporter_creation
    reporter = SmsReporter.create(:uniqueid => '59849943976')
    assert_equal "SMS", reporter.source_name
    report = reporter.reports.create(:uniqueid => '28932389029822', :body => 'whatever you like zip#35216')
    assert_equal 1, reporter.reports.size
    assert_equal "Alabama 35216, USA", report.location.address
  end
  
  def test_phone_reporter_creation
    reporter = PhoneReporter.create(:uniqueid => '4105705739')
    assert_equal "Telephone", reporter.source_name
    report = reporter.reports.create(:uniqueid => '1199998692.10')
    assert_equal 1, reporter.reports.size
  end
end