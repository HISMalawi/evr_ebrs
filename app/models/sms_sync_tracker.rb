class SMSSyncTracker < ActiveRecord::Base
    self.table_name = :sms_sync_tracker

    def self.pending
      self.where(node_service_receipt: false)
    end

    def self.sent
      self.where(node_service_receipt: true)
    end
    
    def self.send_to_sms_service(person_id)
	    tracker = SMSSyncTracker.where(person_id: person_id).first
	    if tracker.blank?
		    tracker = SMSSyncTracker.new
		    tracker.person_id = person_id
		    tracker.node_service_receipt = false
		    tracker.date_of_receipt = nil
		    tracker.date_sent = DateTime.now.to_s(:db)
		    tracker.save
	    end
	    
	    pending_trackers = self.pending	    
           # sms_service_link = "#{SETTINGS["sms_service_link"]}/pending_births"
	    datetime = DateTime.now.to_s(:db)
	    	    
	    pending_trackers.each do |tr|
	        person_id = tr.person_id
                sms_service_link = "#{SETTINGS["sms_service_link"]}/pending_births"
	        sms_service_link = sms_service_link + "?person_id=#{person_id}&datetime=#{datetime}"
                sms_service_link = URI.encode(sms_service_link)
		puts sms_service_link
	    	result = RestClient.get(sms_service_link).as_json
	    	puts result

		if result.to_s == "true"
	    		tr.node_service_receipt = true
	    		tr.date_of_receipt = DateTime.now.to_s(:db)
	    		tr.save
	    	end 
	    end
	        
    end
end
