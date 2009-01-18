# ActionMailer receiver for reports submitted via email
class Receiver < ActionMailer::Base
  def receive(email)
    user_info = { :uniqueid => email.from,
                  :screen_name => email.from,
                  :name => email.friendly_from }
                  
    reporter = EmailReporter.update_or_create(user_info)
    
    parent_report_id = nil
    email.each_part do |part|
      report_info = { :title => email.subject, :parent_report_id => parent_report_id }
      case part.content_type
      when /text/
        report = reporter.text_reports.create(report_info.merge(:body => part.unquoted_body))
      when /image/
        report = reporter.photo_reports.create(report_info)
        File.open(report.filename, 'w') { |f| f.write part.body }
      when /audio/
        report = reporter.audio_reports.create(report_info)
        File.open(report.filename, 'w') { |f| f.write part.body }
      end
      parent_report_id ||= report.id
      p report
    end
  end

  

end
