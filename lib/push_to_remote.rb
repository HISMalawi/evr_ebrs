require 'json'
module PushToRemote
    def self.remote_authenitcation(url,timeout_period,file_name)
        authentication_token = JSON.parse(RestClient::Request.execute(
            :method => :post, 
            :url => "#{url}api/v1/authentication", 
            :payload => { :username => SYNC_SETTINGS[:username], :password => SYNC_SETTINGS[:password]}.to_json, 
            :timeout => timeout_period, 
            :open_timeout => timeout_period, 
            :headers => { :accept => :json, content_type: :json }))
        authentication_token["created_at"] = Time.now
        File.open(file_name,"w") do |f|
            f.write(authentication_token.to_json)
        end
        return authentication_token
    end
    def self.check_authentication(url,timeout_period)
        file_name = "#{Rails.root}/tmp/token.json"
        if File.exist?(file_name)
            content = JSON.parse(File.read(file_name))
            if(Time.now - Time.parse(content['created_at']) >= content['expires_in'])
                authentication_token = self.remote_authenitcation(url,timeout_period,file_name)
            else
                authentication_token = content
            end
        else
            authentication_token = self.remote_authenitcation(url,timeout_period,file_name)
        end
    end
    def self.to_central(person, params)
        ActiveRecord::Base.connection.execute("CREATE TABLE IF NOT EXISTS remote_push_tracker (
                                                remote_push_tracker_id BIGINT NOT NULL AUTO_INCREMENT,
                                                person_id BIGINT NOT NULL,
                                                pushed int(1) NOT NULL,
                                                created_at datetime NOT NULL,
                                                updated_at datetime NOT NULL,
                                                PRIMARY KEY (remote_push_tracker_id),
                                                UNIQUE KEY person_id (person_id),
                                                CONSTRAINT tracker_ibfk_1 FOREIGN KEY (person_id) REFERENCES person (person_id)
                                            ) ENGINE=InnoDB DEFAULT CHARSET=latin1")
        url = "#{SYNC_SETTINGS[:protocol]}://#{SYNC_SETTINGS[:host]}:#{SYNC_SETTINGS[:port]}/"
        #url = URI.parse(url)
        timeout_period = 120
        authentication_token = self.check_authentication(url,timeout_period)
        data = {
            "poc_person_id" => person.id,
            "first_name" =>  params[:person][:first_name],
            "other_name" =>  params[:person][:middle_name],
            "surname" =>  params[:person][:last_name],
            "sex" =>  params[:person][:gender].first,
            "date_of_birth" =>  params[:person][:birthdate],
            "national_id" =>  params[:person][:national_id],
            "place_of_birth" =>  params[:person][:place_of_birth],
            "place_of_birth_district" =>  params[:person][:birth_district],
            "place_of_birth_hospital" =>  params[:person][:hospital_of_birth],
            "place_of_birth_village" =>  params[:person][:place_of_birth_village],
            "place_of_birth_ta" =>  params[:person][:place_of_birth_ta],
            "place_of_birth_other" => params[:person][:other_birth_location],
            "parents_married" =>  (params[:person][:parents_married_to_each_other] == "Yes"),
            "date_of_marriage" =>  params[:person][:date_of_marriage],
            "mother_national_id" =>   params[:person][:mother][:national_id],
            "mother_first_name" =>  params[:person][:mother][:first_name],
            "mother_other_name" =>  params[:person][:mother][:middle_name],
            "mother_surname" =>  params[:person][:mother][:last_name],
            "mother_date_of_birth" =>  params[:person][:mother][:birthdate],
            "mother_nationality" =>  params[:person][:mother][:citizenship],
            "mother_current_country" =>  params[:person][:mother][:residential_country],
            "mother_current_district" =>  params[:person][:mother][:current_district],
            "mother_current_ta" =>  params[:person][:mother][:current_ta],
            "mother_current_village" =>  params[:person][:mother][:current_village],
            "mother_home_country" =>  params[:person][:mother][:home_country],
            "mother_home_district" =>  params[:person][:mother][:home_district],
            "mother_home_ta" =>  params[:person][:mother][:homme_ta],
            "mother_home_village" =>  params[:person][:mother][:home_village],
            "father_national_id" =>  params[:person][:father][:national_id],
            "father_first_name" =>  params[:person][:father][:first_name],
            "father_other_name" =>  params[:person][:father][:middle_name],
            "father_surname" =>  params[:person][:father][:last_name],
            "father_date_of_birth" =>  params[:person][:father][:birthdate],
            "father_nationality" =>  params[:person][:father][:citizenship],
            "father_current_country" =>  params[:person][:father][:residential_country],
            "father_current_district" =>  params[:person][:father][:current_district],
            "father_current_ta" =>  params[:person][:father][:current_ta],
            "father_current_village" =>  params[:person][:father][:current_village],
            "father_home_country" =>  params[:person][:father][:home_country],
            "father_home_district" =>  params[:person][:father][:home_district],
            "father_home_ta" =>  params[:person][:father][:homme_ta],
            "father_home_village" =>  params[:person][:father][:home_village],
            "informant_national_id" => params[:person][:informant][:national_id],
            "informant_first_name" =>  params[:person][:informant][:first_name],
            "informant_other_name" =>  params[:person][:informant][:middle_name],
            "informant_surname" =>  params[:person][:informant][:last_name],
            "informant_date_of_birth" =>  params[:person][:informant][:birthdate],
            "informant_nationality" =>  params[:person][:informant][:citizenship],
            "informant_current_country" =>  params[:person][:informant][:residential_country],
            "informant_current_district" =>  params[:person][:informant][:current_district],
            "informant_current_ta" =>  params[:person][:informant][:current_ta],
            "informant_current_village" =>  params[:person][:informant][:current_village],
            "informant_postal_address" =>  "",
            "informant_phone_number" =>  params[:person][:informant][:informant_phone_number],
            "date_informant_signed" =>  params[:date_reported],
            "informant_relationship_to_child" =>  (params[:informant_same_as_mother] == "Yes"? "Mother" :  (params[:informant_same_as_father] == "Yes"? "Father" :  "Other")),
            "place_of_registration_district" =>  params[:person][:place_of_registration_district],
            "place_of_registration_hospital" =>  params[:person][:place_of_registration_hospital],
            "place_of_registration_ta" =>   params[:person][:place_of_registration_ta],
            "place_of_registration_village" =>  params[:person][:place_of_registration_village],
            "birth_entry_number" =>  params[:birth_entry_number],
            "birth_registration_number" =>  params[:birth_registration_number],
            "gestation_at_birth" =>  params[:gestation_at_birth],
            "level_of_education" =>  params[:person][:level_of_education],
            "mode_of_delivery" =>  params[:person][:mode_of_delivery],
            "type_of_birth" =>  params[:person][:type_of_birth],
            "registration_type" =>  params[:person][:relationship],
            "birth_weight" =>  params[:person][:birth_weight],
            "number_of_prenatal_visits"  =>  params[:number_of_prenatal_visits], 
            "month_prenatal_care_started"  =>  params[:month_prenatal_care_started], 
            "number_of_children_born_alive_inclusive" =>  params[:number_of_children_born_alive_inclusive], 
            "number_of_children_born_still_alive" =>  params[:number_of_children_born_still_alive],
            "record_users" => params[:users],
            "statuses" => params[:statuses]
        }
  
        begin 
            #reponse =JSON.parse(RestClient::Request.execute(,data, {:Authorization => "Bearer #{}", :ContentType => 'application/json'}))
            
            response = RestClient::Request.execute(
                :method => :post,
                :url => "#{url}api/v1/poc/birth_records",
                :verify_ssl =>  false,
                :headers => { 
                  :Authorization => "Bearer #{authentication_token['access_token']}", 
                  :content_type => :json,
                  :accept => :json
                },
                :payload => "#{data.to_json}"
              )
            response = JSON.parse(response)
            puts response
            self.insert_update_tracker(person.id, 1)
        rescue
            self.insert_update_tracker(person.id, 0)
        end
        return response
    end
    def self.insert_update_tracker(person_id, status)
        tracker_record = ActiveRecord::Base.connection.select_one("SELECT * FROM remote_push_tracker WHERE person_id=#{person_id}")
        if tracker_record.present?
            ActiveRecord::Base.connection.execute("UPDATE remote_push_tracker SET pushed=#{status} WHERE person_id=#{person_id}") rescue nil
        else
            ActiveRecord::Base.connection.execute("INSERT INTO remote_push_tracker(person_id,pushed,created_at,updated_at) VALUES(#{person_id},#{status},NOW(),NOW())") rescue nil
        end
    end
    def self.format_for_birth(person_id)
        pbd = PersonBirthDetail.find_by_person_id(person_id)
        person = Person.find_by_person_id(pbd.person_id)
        person_name = PersonName.find_by_person_id(pbd.person_id)
        national_id = ""
        birth_entry_number = ""
        birth_registration_number = ""
        person_identifiers = PersonIdentifier.where(person_id: pbd.person_id)
       
        person_identifiers.each do |i|
            if i.person_identifier_type_id == 4 
                national_id = i.value
            end
            if i.person_identifier_type_id == 2
                birth_entry_number = i.value
            end
            if i.person_identifier_type_id == 3
                birth_registration_number = i.value
            end
        end
        district_of_birth = Location.find(pbd.district_of_birth).name
        place_of_birth = Location.find(pbd.place_of_birth).name
        place_of_birth_hospital = nil
        if  place_of_birth == "Hospital"
            place_of_birth_hospital = Location.find(pbd.birth_location_id).name
        end
        place_of_birth_ta = nil
        place_of_birth_village = nil
        if place_of_birth == "Home"
            place_of_birth_village = (Location.find(pbd.birth_location_id).name rescue "")
            place_of_birth_ta = (Location.find(Location.find(pbd.birth_location_id).parent_location).name rescue "")
        end
        place_of_registration_district = ""
        place_of_registration_ta = ""
        place_of_registration_village= ""
        place_of_registration_hospital = ""
        if pbd.location_created_at.present?
            if Location.find(pbd.location_created_at).present?
                location = Location.find(pbd.location_created_at)
                parent_location = nil
                great_parent_location = nil
                if location.parent_location.present? 
                    parent_location = Location.find(location.parent_location)
                    if parent_location.parent_location.present?
                        great_parent_location =  Location.find(parent_location.parent_location)
                    end
                end
                if great_parent_location.present?
                    place_of_registration_district = (great_parent_location.name rescue "")
                    place_of_registration_ta = (parent_location.name rescue "")
                    place_of_registration_village = (location.name rescue "")
                elsif great_parent_location.blank? && parent_location.present?
                    place_of_registration_district = (parent_location.name rescue "")
                    place_of_registration_hospital = (location.name rescue "")
                else
                    place_of_registration_district = (location.name rescue "")
                end
            end
        end
        person_relationship = PersonRelationship.where(person_a: person.id)
        father_person = nil
        father_national_id = nil
        father_name = nil
        father_address = nil  
        mother_person = nil
        mother_national_id = nil
        mother_name = nil
        mother_address = nil 
        informant_person = nil
        informant_national_id = nil
        informant_name = nil
        informant_address = nil 
        
        person_relationship.each do |pr|
            if pr.person_relationship_type_id == 1
                father_person = Person.find(pr.person_b)
                father_name = PersonName.find_by_person_id(pr.person_b)
                father_address = PersonAddress.find_by_person_id(pr.person_b)
                father_address = PersonAddress.new if father_address.blank?
                father_identifiers = PersonIdentifier.where(person_id:pr.person_b)
                father_identifiers.each do |i|
                    if i.person_identifier_type_id == 4 
                        father_national_id = i.value
                    end
                end
            end
            if pr.person_relationship_type_id == 5
                mother_person = Person.find(pr.person_b)
                mother_name = PersonName.find_by_person_id(pr.person_b)
                mother_address = PersonAddress.find_by_person_id(pr.person_b)
                mother_address = PersonAddress.new if mother_address.blank?
                mother_identifiers = PersonIdentifier.where(person_id:pr.person_b)
                mother_identifiers.each do |i|
                    if i.person_identifier_type_id == 4 
                        mother_national_id = i.value
                    end
                end
            end
            if pr.person_relationship_type_id == 4
                informant_person = Person.find(pr.person_b)
                informant_name = PersonName.find_by_person_id(pr.person_b)
                informant_address = PersonAddress.find_by_person_id(pr.person_b)
                informant_address = PersonAddress.new if informant_address.blank?
                informant_phone_number  =  PersonAttribute.find_by(person_id: pr.person_b, person_attribute_type_id: 4)
                informant_identifiers = PersonIdentifier.where(person_id:pr.person_b)
                informant_identifiers.each do |i|
                    if i.person_identifier_type_id == 4 
                        informant_national_id = i.value
                    end
                end
            end
        end
        users  = []
        statuses = ActiveRecord::Base.connection.select_all("SELECT ps.person_id, s.status_id, s.name, ps.comments, ps.voided, ps.creator, ps.created_at, ps.updated_at FROM person_record_statuses ps INNER JOIN statuses s ON ps.status_id = s.status_id WHERE person_id=#{person_id}")
        statuses.each do |status|
            user = (ActiveRecord::Base.connection.select_one("SELECT u.*,p.birthdate,p.gender, pn.first_name, pn.last_name, pn.middle_name FROM users u LEFT JOIN person p ON u.person_id = p.person_id LEFT JOIN person_name pn ON p.person_id = pn.person_id WHERE u.user_id=#{status['creator']}").as_json rescue nil)
            next if user.blank?
            users << user
        end
        mother = {}
        mother = {
                :first_name => mother_name.first_name,
                :middle_name => mother_name.middle_name,
                :national_id => mother_national_id,
                :last_name => mother_name.last_name,
                :birthdate => mother_person.birthdate,
                :citizenship => (mother_address.present? && mother_address.citizenship.present? ? Location.find(mother_address.citizenship).country : ""),
                :residential_country => (mother_address.present? && mother_address.residential_country.present? ? Location.find(mother_address.residential_country).name : ""),
                :current_district =>  ((Location.find(mother_address.current_district) rescue nil).present? ? Location.find(mother_address.current_district).name : nil ),
                :current_ta =>  ((Location.find(mother_address.current_ta) rescue nil).present? ? Location.find(mother_address.current_ta).name : (mother_address.current_ta_other rescue "")),
                :current_village =>  ((Location.find(mother_address.current_village) rescue nil).present? ? Location.find(mother_address.current_village).name : (mother_address.current_village_other rescue "") ),
                :home_country =>  ((Location.find(mother_address.citizenship) rescue nil).present? ? Location.find(mother_address.citizenship).name : nil ),
                :home_district =>  ((Location.find(mother_address.home_district) rescue nil).present? ? Location.find(mother_address.home_district).name : nil ),
                :home_ta =>  ((Location.find(mother_address.home_ta) rescue nil).present? ? Location.find(mother_address.home_ta).name : (mother_address.home_ta_other rescue "")),
                :home_village =>  ((Location.find(mother_address.home_village) rescue nil).present? ? Location.find(mother_address.home_village).name : (mother_address.home_village_other rescue ""))
            }
        father = {}
        if father_person.present?
            father = {
                :first_name => father_name.first_name,
                :middle_name => father_name.middle_name,
                :last_name => father_name.last_name,
                :national_id => father_national_id,
                :birthdate => father_person.birthdate,
                :citizenship => (father_address.present? && father_address.citizenship.present? ? Location.find(father_address.citizenship).country : ""),
                :residential_country => (father_address.present? && father_address.residential_country.present? ? Location.find(father_address.residential_country).name : ""),
                :current_district =>  ((Location.find(father_address.current_district) rescue nil).present? ? Location.find(father_address.current_district).name : nil ),
                :current_ta =>  ((Location.find(father_address.current_ta) rescue nil).present? ? Location.find(father_address.current_ta).name : (father_address.current_ta_other rescue "")),
                :current_village =>  ((Location.find(father_address.current_village) rescue nil).present? ? Location.find(father_address.current_village).name : (father_address.current_village_other rescue "") ),
                :home_country =>  ((Location.find(father_address.citizenship) rescue nil).present? ? Location.find(father_address.citizenship).name : nil ),
                :home_district =>  ((Location.find(father_address.home_district) rescue nil).present? ? Location.find(father_address.home_district).name : nil ),
                :home_ta =>  ((Location.find(father_address.home_ta) rescue nil).present? ? Location.find(father_address.home_ta).name : (father_address.home_ta_other rescue "")),
                :home_village =>  ((Location.find(father_address.home_village) rescue nil).present? ? Location.find(father_address.home_village).name : (father_address.home_village_other rescue ""))
            }
        end
        if informant_person.present?
            informant = {
                :first_name => informant_name.first_name,
                :middle_name => informant_name.middle_name,
                :last_name => informant_name.last_name,
                :national_id => informant_national_id,
                :birthdate => informant_person.birthdate,
                :citizenship => (informant_address.present? && informant_address.citizenship.present? ? Location.find(informant_address.citizenship).country : ""),
                :residential_country => (informant_address.present? && informant_address.residential_country.present? ? Location.find(informant_address.residential_country).name : ""),
                :current_district =>  ((Location.find(informant_address.current_district) rescue nil).present? ? Location.find(informant_address.current_district).name : nil ),
                :current_ta =>  ((Location.find(informant_address.current_ta) rescue nil).present? ? Location.find(informant_address.current_ta).name : (informant_address.current_ta_other rescue "")),
                :current_village =>  ((Location.find(informant_address.current_village) rescue nil).present? ? Location.find(informant_address.current_village).name : (informant_address.current_village_other rescue "") ),
                :home_country =>  ((Location.find(informant_address.citizenship) rescue nil).present? ? Location.find(informant_address.citizenship).name : nil ),
                :home_district =>  ((Location.find(informant_address.home_district) rescue nil).present? ? Location.find(informant_address.home_district).name : nil ),
                :home_ta =>  ((Location.find(informant_address.home_ta) rescue nil).present? ? Location.find(informant_address.home_ta).name : (informant_address.home_ta_other rescue "")),
                :home_village =>  ((Location.find(informant_address.home_village) rescue nil).present? ? Location.find(informant_address.home_village).name : (informant_address.home_village_other rescue "")),
                :informant_phone_number => (informant_phone_number.value rescue "")
            }
        end
        brn_counter = (ActiveRecord::Base.connection.select_one("SELECT * FROM brn_counter WHERE person_id = #{person_id}")['counter'] rescue nil)
        params = {
            :person => {
                :first_name => person_name.first_name,
                :middle_name => person_name.middle_name,
                :last_name => person_name.last_name,
                :gender => person.gender,
                :national_id => national_id,
                :birthdate => person.birthdate,
                :place_of_birth =>  place_of_birth,
                :place_of_birth_ta=>  place_of_birth_ta,
                :place_of_birth_village =>  place_of_birth_village,
                :birth_district =>  district_of_birth,
                :hospital_of_birth =>  place_of_birth_hospital,
                :other_birth_location =>pbd.other_birth_location,
                :parents_married_to_each_other =>( pbd.parents_married_to_each_other == 1 ? "Yes": "No"),
                :date_of_marriage => pbd.date_of_marriage,
                :place_of_registration_district =>  place_of_registration_district,
                :place_of_registration_ta =>  place_of_registration_ta,
                :place_of_registration_village =>  place_of_registration_village,
                :place_of_registration_hospital =>  place_of_registration_hospital,
                :mother =>mother,
                :father =>father,
                :informant =>informant,
                :level_of_education => (LevelOfEducation.find(pbd.level_of_education_id).name rescue nil ),
                :mode_of_delivery => (ModeOfDelivery.find(pbd.mode_of_delivery_id).name rescue nil),
                :type_of_birth => (PersonTypeOfBirth.find(type_of_birth).name rescue pbd.other_type_of_birth),
                :relationship => pbd.informant_relationship_to_person,
                :birth_weight => pbd.birth_weight
    
            },
            :gestation_at_birth =>pbd.gestation_at_birth,
            :month_prenatal_care_started => pbd.month_prenatal_care_started,
            :number_of_prenatal_visits => pbd.number_of_prenatal_visits,
            :number_of_children_born_alive_inclusive => pbd.number_of_children_born_alive_inclusive,
            :number_of_children_born_still_alive => pbd.number_of_children_born_still_alive,
            :birth_registration_type => (BirthRegistrationType.find(pbd.birth_registration_type_id) rescue "Normal"),
            :users => (users.as_json rescue []),
            :statuses => (statuses.as_json rescue []),
            :birth_entry_number => (birth_entry_number.present? ? birth_entry_number : (pbd.district_id_number rescue "")),
            :birth_registration_number => (birth_registration_number.present? ? birth_registration_number: (brn_counter rescue "")),
            :date_reported => (pbd.date_reported.present? pbd.date_reported : pbd.created_at)
        }
    end

end