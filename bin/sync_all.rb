PersonBirthDetail.all.order("created_at DESC").each do |pbd|
    params = PushToRemote.format_for_birth(pbd['person_id'])
    person = Person.find(pbd['person_id'])
    response = PushToRemote.to_central(person, params)
    puts "Sent #{response}"
end