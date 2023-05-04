ActiveRecord::Base.connection.select_all("SELECT person_id FROM remote_push_tracker WHERE pushed = 0").each do |pid|
    params = PushToRemote.format_for_birth(pid['person_id'])
    person = Person.find(pid['person_id'])
    response = PushToRemote.to_central(person, params)
    puts "Sent #{response}"
end