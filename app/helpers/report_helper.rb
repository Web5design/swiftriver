module ReportHelper

      US_STATES = [ 	
	['Select a State', 'None'],
	['Alabama', 'AL'], 
	['Alaska', 'AK'],
	['Arizona', 'AZ'],
	['Arkansas', 'AR'], 
	['California', 'CA'], 
	['Colorado', 'CO'], 
	['Connecticut', 'CT'], 
	['Delaware', 'DE'], 
	['District Of Columbia', 'DC'], 
	['Florida', 'FL'],
	['Georgia', 'GA'],
	['Hawaii', 'HI'], 
	['Idaho', 'ID'], 
	['Illinois', 'IL'], 
	['Indiana', 'IN'], 
	['Iowa', 'IA'], 
	['Kansas', 'KS'], 
	['Kentucky', 'KY'], 
	['Louisiana', 'LA'], 
	['Maine', 'ME'], 
	['Maryland', 'MD'], 
	['Massachusetts', 'MA'], 
	['Michigan', 'MI'], 
	['Minnesota', 'MN'],
	['Mississippi', 'MS'], 
	['Missouri', 'MO'], 
	['Montana', 'MT'], 
	['Nebraska', 'NE'], 
	['Nevada', 'NV'], 
	['New Hampshire', 'NH'], 
	['New Jersey', 'NJ'], 
	['New Mexico', 'NM'], 
	['New York', 'NY'], 
	['North Carolina', 'NC'], 
	['North Dakota', 'ND'], 
	['Ohio', 'OH'], 
	['Oklahoma', 'OK'], 
	['Oregon', 'OR'], 
	['Pennsylvania', 'PA'], 
	['Rhode Island', 'RI'], 
	['South Carolina', 'SC'], 
	['South Dakota', 'SD'], 
	['Tennessee', 'TN'], 
	['Texas', 'TX'], 
	['Utah', 'UT'], 
	['Vermont', 'VT'], 
	['Virginia', 'VA'], 
	['Washington', 'WA'], 
	['West Virginia', 'WV'], 
	['Wisconsin', 'WI'], 
	['Wyoming', 'WY']]
        
  # TODO: DCT - commented this out because object cannot be found; need a gem or a lib?
  #include BumpsparkHelper 

  def state_select(current = "")
    select(:filter, :state, US_STATES)
  end
  
  def media_link(report)
    case report.class.name
    when /AudioReport/
      return "<embed src='#{report.url}' width='100' height='20' AUTOPLAY='false'/>"
    when /PhotoReport/
      report.link_url ? "<a href='#{report.link_url}' class='imageLink' target='new'><img src='#{report.url}' width='180'/></a>" :
        "<a href='#{report.large_url}' class='imageLink' target='new'><img src='#{report.url}' width='180'/></a>"
    when /VideoReport/
      report.link_url ? "<a href='#{report.link_url}' class='imageLink' target='new'><img src='#{report.url}' width='180'/></a>" : "<img src='#{report.url}' width='180'/>"
    else
      return ""
    end
  end
  
  def score_icon(score)
    if(score.nil?)
      score_icon = "score_none.png"
    elsif(score <= 30)
      score_icon = "score_bad.png"
    elsif (score <= 70)
      score_icon = "score_medium.png"
    else
      score_icon = "score_good.png"
    end    
    "#{SERVER_URL}/images/#{score_icon}"
  end
  
  def bumpspark2( results )
     white, red, grey = 0, 16, 32
     padding = 3 - ( results.length - 1 ) % 4
     ibmp = results.inject([]) do |ary, r|
         ary << [white]*15
         ary.last[r/9,4] = [(r > 50 and red or grey)]*4
         ary
     end.transpose.map do |px|
         px.pack("C#{px.length}x#{padding}")
     end.join
     ["BM", ibmp.length + 66, 0, 0, 66, 40,
       results.length * 2, 15, 1, 4, 0, 0, 0, 0, 3, 0,
       0xFFFFFF, 0xFF0000, 0x999999 ].
       pack("A2Vv2V4v2V9") + ibmp
  end
 
  def display(val, default='Undefined')
    (val.blank?) ? default : val.to_s.strip
  end
end