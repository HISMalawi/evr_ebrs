unless ActiveRecord::Base.connection.table_exists?(:sms_sync_tracker)
  ActiveRecord::Base.connection.create_table :sms_sync_tracker do |t|
    t.integer :person_id
    t.boolean :node_service_receipt
    t.datetime :date_sent
    t.datetime :date_of_receipt
  end
end
