require File.dirname(__FILE__) + '/../test_helper'

class ReportTest < ActiveSupport::TestCase
  fixtures :reports, :users, :tags
  
  def setup
    @twitter_reporter = reporters(:reporters_001)
    @sms_reporter = reporters(:reporters_011)
  end
  
  # Tests to be sure that locations are detected properly
  def test_location_detection
    # Google geocoder isn't returning the postal code?
    # assert_equal "80303", @twitter_reporter.reports.create(:body => 'Long wait in #80303').location.postal_code
    
    assert_equal "Boston, MA 02130, USA", @twitter_reporter.reports.create(:body => 'Insane lines at #zip-02130').location.address
    assert_equal "90 Church Rd, Arnold, MD 21012, USA", @twitter_reporter.reports.create(:body => 'L:90 Church Road, Arnold, MD: bad situation').location.address
    # assert_equal "21804", @twitter_reporter.reports.create(:body => '#zip21804 weird stuff happening').location.postal_code
    assert_equal "Church Hill", @twitter_reporter.reports.create(:body => 'Things are off in L:Church Hill, MD').location.locality
    # assert_equal "94107", @twitter_reporter.reports.create(:body => 'No 94107 worries!').location.postal_code
    # assert_equal "21012", @twitter_reporter.reports.create(:body => 'going swimmingly l:21012-2423').zip
    assert_equal "Severna Park, MD, USA", @twitter_reporter.reports.create(:body => 'Long lines at l:severna park senior HS').location.address
    assert_equal "New York 11215, USA", @twitter_reporter.reports.create(:body => 'wait:105 in Park Slope, Brooklyn zip11215 #votereport').location.address
    assert_equal "Courthouse, Virginia, USA", @twitter_reporter.reports.create(:body => 'no joy and long wait in l:courthouse, va').location.address
    # with mis-spelling:
    assert_equal "Boulder, CO, USA", @twitter_reporter.reports.create(:body => 'long lines at courthouse L:Bolder CO').location.address
  end
  
  # Tests to be sure that tags are properly assigned to a given report
  # and that reports are scored correctly
  def test_tag_assignment
    assert_equal 2, @twitter_reporter.reports.create(:body => 'my #machine is #good').tags.size
    # assert_equal 7, @twitter_reporter.reports.create(:body => 'many #challenges here, #bad').score
    goodreport = @twitter_reporter.reports.create(:body => 'no problems #good overall, #wait12')
    goodreport.reload
    assert_equal 2, goodreport.tags.size
    epreport = @twitter_reporter.reports.create(:body => 'being #challenges here #EPOH l:cincinnati oh')
    epreport.reload
    assert_equal 2, epreport.tags.size
    # FIXM - figure out how to get EPXX back into the tag_list, all we have is the pattern here
    #assert epreport.tag_list.split(Tag::TAG_SEPARATOR).include?('EPOH'), "has tag_list: #{epreport.tag_list}"
  end
  
  def test_reviewed_arent_reassigned
    report = reports(:reports_022)
    report.confirm! # confirms without user_id
    report.reload
    assert report.is_confirmed?
    assert_not_nil report.reviewed_at
    assert !Report.unassigned.include?(report)

    report = reports(:reports_001)
    report.confirm!(users(:quentin))
    report.reload
    assert report.is_confirmed?
    assert_not_nil report.reviewed_at
    assert !Report.unassigned.include?(report)
  end
  
  def test_tag_assignment_by_string
    report = @twitter_reporter.reports.create(:body => 'all is well in 94107')
    assert report.tags.empty?, "there should be no tags at this point"
    report.tag_list = "registration machine challenges bogus ballots good bad"
    report.save!
    assert !report.tags.empty?, "tags should not be empty"
    assert_equal 7, report.tags.size, "there should be seven tags"
    assert report.tag_list.split(Tag::TAG_SEPARATOR).include?('bogus')
  end
  
  def test_tag_cache
    report = @twitter_reporter.reports.create(:body => 'no problems #good overall, #wait12')
    assert_equal 'good|wait12', report.tag_list("|"), "all tags should be included"
  end
  
  
  # Tests to be sure that a report made in a particular location
  # is asoociated with the correct geographical filters - subject to fixtures
  def test_filter_creation
    md_report = @twitter_reporter.reports.create(:body => 'here in #21108')
    assert_equal 5, (md_report.filters & %w(annapolis baltimore maryland northamerica unitedstates).map { |c| Filter.find_by_name(c) }).size
    ca_report = @twitter_reporter.reports.create(:body => 'all is well in 94107')
    assert_equal 4, (ca_report.filters & %w(sanfrancisco california northamerica unitedstates).map { |c| Filter.find_by_name(c) }).size
  end
  
  def test_review_assignment
    reports = Report.unassigned(:limit => 10).assign(users(:quentin))
    assert_equal 10, reports.size
    reports.each do |r|
      assert_equal users(:quentin), r.reviewer
    end
    assert_equal reports.size, Report.assigned(users(:quentin)).size
  end
  
  def test_reviewed_arent_reassigned
    report = reports(:reports_022)
    report.confirm! # confirms without user_id
    report.reload
    assert report.is_confirmed?
    assert_not_nil report.reviewed_at
    assert !Report.unassigned.include?(report)

    report = reports(:reports_001)
    report.confirm!(users(:quentin))
    report.reload
    assert report.is_confirmed?
    assert_not_nil report.reviewed_at
    assert !Report.unassigned.include?(report)
  end
  
  # not currently any auto_review  
  # def test_auto_review
  #   new_report = @twitter_reporter.reports.create(:body => 'i got #early #reg #challenges #wait:10 some tags 11222')
  #   new_report.reload # check that the value is actually saved to the model
  #   assert_not_nil new_report.reviewed_at
  #   assert !Report.unassigned.include?(new_report)
  # end
  # 
  ##########################
  
  def create_report(text)
    @twitter_reporter.reports.create(:body => text)
  end
end
