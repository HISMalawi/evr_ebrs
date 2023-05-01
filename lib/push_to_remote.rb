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
        url = URI.parse(url)
        timeout_period = 120
        authentication_token = self.check_authentication(url,timeout_period)
        data = {
            "dec_person_id" =>  "",
            "first_name" =>  params[:person][:first_name],
            "other_name" =>  params[:person][:middle_name],
            "surname" =>  params[:person][:last_name],
            "sex" =>  params[:person][:gender].first,
            "date_of_birth" =>  params[:person][:birthdate],
            "national_id" =>  "",
            "place_of_birth" =>  "Health Facility",
            "place_of_birth_district" =>  params[:person][:birth_district],
            "place_of_birth_hospital" =>  params[:person][:hospital_of_birth],
            "place_of_birth_village" =>  "",
            "place_of_birth_ta" =>  "",
            "parents_married" =>  (params[:person][:parents_married_to_each_other] == "Yes"),
            "date_of_marriage" =>  params[:person][:date_of_marriage],
            "mother_national_id" =>  "",
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
            "father_national_id" =>  "",
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
            "informant_phone_number" =>  "",
            "date_informant_signed" =>  params[:date_reported],
            "informant_relationship_to_child" =>  (params[:informant_same_as_mother] == "Yes"? "Mother" :  (params[:informant_same_as_father] == "Yes"? "Father" :  "Other")),
            "place_of_registration_district" =>  params[:person][:birth_district],
            "place_of_registration_hospital" =>  params[:person][:hospital_of_birth],
            "place_of_registration_ta" =>  "",
            "place_of_registration_village" =>  "",
            "birth_entry_number" =>  "",
            "birth_registration_number" =>  "",
            "gestation_at_birth" =>  params[:gestation_at_birth],
            "level_of_education" =>  params[:person][:level_of_education],
            "mode_of_delivery" =>  params[:person][:mode_of_delivery],
            "type_of_birth" =>  params[:person][:type_of_birth],
            "registration_type" =>  params[:person][:relationship],
            "birth_weight" =>  params[:person][:birth_weight],
            "number_of_prenatal_visits"  =>  params[:number_of_prenatal_visits], 
            "month_prenatal_care_started"  =>  params[:month_prenatal_care_started], 
            "number_of_children_born_alive_inclusive" =>  params[:number_of_children_born_alive_inclusive], 
            "number_of_children_born_still_alive" =>  params[:number_of_children_born_still_alive]
        }
        begin 
            reponse =JSON.parse(RestClient.post("#{url}api/v1/poc/records",data,{:Authorization => "Bearer #{authentication_token['access_token']}"}))
            ActiveRecord::Base.connection.execute("INSERT INTO remote_push_tracker(person_id,pushed,created_at,updated_at) VALUES(#{person.id},1,NOW(),NOW())") rescue nil
        rescue
            ActiveRecord::Base.connection.execute("INSERT INTO remote_push_tracker(person_id,pushed,created_at,updated_at) VALUES(#{person.id},0,NOW(),NOW())") rescue nil
        end
        return reponse
    end

end