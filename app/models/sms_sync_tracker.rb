class SMSSyncTracker < ActiveRecord::Base
    self.table_name = :sms_sync_tracker

    def self.pending
      self.where(node_service_receipt: false)
    end

    def self.sent
      self.where(node_service_receipt: true)
    end
end
