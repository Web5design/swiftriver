require File.dirname(__FILE__) + '/../test_helper'

class ReceiverTest < ActionMailer::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures/receiver'

  test "multipart report is received properly" do
    email_text = File.read("#{FIXTURES_PATH}/taylor_swift")
    assert_match /Taylor-Swift/, email_text
    original_reports = Report.count
    Receiver.receive(email_text)
    assert_equal 3, Report.count - original_reports
  end

  test "single part report is received properly" do
    email_text = File.read("#{FIXTURES_PATH}/single_part_email")
    original_reports = Report.count
    Receiver.receive(email_text)
    report = Report.find(:last)
    assert_equal 1, Report.count - original_reports
    assert_match /single part email/, report.body
  end
end
