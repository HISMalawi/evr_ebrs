class MaternityController < ApplicationController
  
  def get_birth_report
  	
  	result = {}

  	  	 	
  	person_id = params[:person_id]  		  	
  	detail = PersonBirthDetail.where(person_id: person_id).first
  	child_name = PersonName.where(person_id: person_id, voided: 0).last
  	person = Person.find(person_id)
  	
  	mother_person = person.mother
  	mother_name = mother_person.person_names.last
  	mother_address = mother_person.addresses.last	
  	
  	father_person = person.father
  	father_name = father_person.person_names.last
  	father_address     = father_person.addresses.last
  	
  	
  	informant_person = person.informant
  	informant_name = informant_person.person_names.last
  	informant_address  = informant_person.addresses.last
  	
  	cell_phone_attribute_type_id = PersonAttributeType.where(name: "Cell Phone Number").first.id
  	phone_number = PersonAttribute.where(person_id: informant_person.id, person_attribute_type_id: cell_phone_attribute_type_id, voided: 0).last.value
  	
  	result = {
  			"child_details"  => {
  				"first_name"   => child_name.first_name,
  				"middle_name"  => child_name.middle_name,
  				"last_name"    => child_name.last_name,
  				"birth_date"   => person.birthdate,
  				"gender"       => person.gender,
  				"birth_weight" => detail.birth_weight,
  				"type_of_birth" => detail.type_of_birth,
  				"other_type_of_birth" => detail.other_type_of_birth,
  				"parents_married"  => detail.parents_married_to_each_other,
  				"date_of_marriage" => detail.date_of_marriage,
  				"court_order_attached" => detail.court_order_attached,
  				"parents_signed"       => detail.parents_signed  	
  			},
  			
  			"mother_details" => {
  				"first_name" => mother_name.first_name,
  				"maiden_name" => mother_person.middle_name,
  				"last_name" => mother_person.last_name,
  				"birth_date" => mother_person.birthdate,
  				"citizenship" => mother_address.citizenship,
  				"home_district" => mother_address.home_district,
  				"home_ta" => mother_address.home_ta,
  				"home_village" => mother_address.home_village,
  				"residential_country" => mother_address.residential_country,
  				"current_district" =>  mother_address.current_district,
  				"current_ta" => mother_address.current_ta,
  				"current_village" =>  mother_address.current_village,
  				"gestation_at_birth" => detail.gestation_at_birth,
  				"number_of_prenatal_visits" => detail.number_of_prenatal_visits,
  				"month_prenatal_care_started" => detail.month_prenatal_care_started,
  				"mode_of_delivery" => detail.mode_of_delivery_id,
  				"number_of_children_born_alive_inclusive" => detail.number_of_children_born_alive_inclusive,
  				"number_of_children_born_still_alive" => detail.number_of_children_born_still_alive,
  				"level_of_education" => detail.level_of_education_id
  			},
  			
  			"father_details" => {
  				"first_name" => father_name.first_name,
  				"middle_name" => father_name.middle_name,
  				"last_name" => father_name.last_name,
  				"birth_date" => father_person.birthdate,
  				"citizenship" => father_address.citizenship,
  				"home_district" => father_address.home_district,
  				"home_ta" => father_address.home_ta,
  				"home_village" => father_address.home_village,
  				"residential_country" => father_address.residential_country,
  				"current_district" => father_address.current_district,
  				"current_ta" => father_address.current_ta,
  				"current_village" => father_address.current_village
  			},
  			
  			"informant_details" => {
  				"mother_is_informant" => ((detail.informant_relationship_to_person == "Mother") ? 1 : 0),
  				"father_is_informant" => ((detail.informant_relationship_to_person == "Father") ? 1 : 0),
  				"relationship_to_child" => detail.informant_relationship_to_person,
  				"first_name" => informant_name.first_name,
  				"middle_name" => informant_name.middle_name,
  				"last_name" => informant_name.last_name,
  				"home_district" => informant_address.home_district,
  				"home_ta" => informant_address.home_ta,
  				"home_village" => informant_address.home_village,
  				"current_district" => informant_address.current_district,
  				"current_ta" => informant_address.current_ta,
  				"current_village" => informant_address.current_village,
  				"phone_number"   => "",
  				"form_signed" => detail.form_signed,
  				"date_reported" => detail.date_reported
  			}  						
  		}
  	
  	render :json => result.to_json
  
  end
  
  def create_from_maternity

    type_of_birth = params[:person][:type_of_birth]

    if type_of_birth == 'Twin'

      type_of_birth = 'First Twin'
      params[:person][:type_of_birth] = 'First Twin'

    elsif type_of_birth == 'Triplet'

      type_of_birth = 'First Triplet'
      params[:person][:type_of_birth] = 'First Triplet'
    end

    @person = PersonService.create_record(params)

    # when creating from dde directly from eBRS
    if SETTINGS['scan_from_dde'].to_s == "true"

      link  = ""

    elsif SETTINGS['scan_from_remote'].to_s == "true"
      # when creating from remote [ART]
      link = "http://#{SETTINGS['remote_user_name']}:#{SETTINGS['remote_user_password']}@#{SETTINGS['remote_url']}/patient/create_remote"

      if SETTINGS['remote_dde_status'].to_s == "true"
        # if remote [ART] has dde status enabled
        # raise params.inspect
        birthdate = params['person']['birthdate']

        params['patient_day'] = birthdate.to_datetime.day
        params['patient_month'] = birthdate.to_datetime.month
        params['patient_year'] = birthdate.to_datetime.year

        demographics_hash = {
            "person" => {
                "birth_year" => params['patient_year'],
                "birth_month" => params['patient_month'],
                "birth_day" => params['patient_day'],
                "names" => {
                    "family_name" => params["person"]["first_name"],
                    "given_name" => params["person"]["last_name"],
                    "middle_name" => (params["person"]["names"]["middle_name"] rescue [])
                },
                "gender" => params["person"]["gender"],
                "addresses" => {
                    "city_village" => params["person"]["mother"]["current_village"],
                    "township_division" => (params["person"]["mother"]["current_ta"] rescue []),
                    "state_province" => params["person"]["mother"]["current_district"],

                    "neighborhood_cell" => params["person"]["mother"]["home_village"],
                    "county_district" => params["person"]["mother"]["home_ta"],
                    "address2" => params["person"]["mother"]["home_district"]
                },
            }
        }
      else
        # if remote [ART] has dde status disabled

        birthdate = params['person']['birthdate']

        params['birth_day'] = birthdate.to_datetime.day
        params['birth_month'] = birthdate.to_datetime.month
        params['birth_year'] = birthdate.to_datetime.year

        demographics_hash = {
            'occupation' =>"#{(params['attributes']['occupation'] rescue [])}",
            'education_level'=>"#{(params['person']['level_of_education'] rescue [])}",
            'religion'=>"#{(params['attributes']['religion'] rescue [])}",
            'patient_year'=>"#{params['birth_year'] rescue []}",
            'patient'=> {
                'gender' =>"#{params['person']['gender']}",
                'birthplace' =>"#{params['addresses']['address2'] rescue []}",
                'creator' => 1,
                'changed_by' => 1
            },
            'p_address'=> {
                'identifier' => "#{params['addresses']['state_province'] rescue []}"},
            'home_phone' => {
                'identifier' => "#{(params['attributes']['home_phone_number'] rescue [])}"},
            'cell_phone' => {
                'identifier' => "#{(params['attributes']['cell_phone_number'] rescue [])}"},
            'office_phone' => {
                'identifier' => "#{(params['attributes']['office_phone_number'] rescue [])}"},
            'patient_id' => '',
            'patient_day' => "#{params['birth_day']}",
            'patientaddress' => {'city_village' => "#{new_params['addresses']['city_village'] rescue []}"},
            'patient_name' => {
                'family_name' => "#{params['person']['first_name']}",
                'given_name' => "#{params['person']['last_name']}",
                'creator' => 1
            },
            'patient_month' => "#{params['birth_month']}",
            'patient_age' =>{
                'age_estimate' => "#{params['age_estimate']}"
            },
            'age' =>{
                'identifier' =>''
            },
            'current_ta' =>{
                'identifier' => "#{params['addresses']['county_district'] rescue []}"
            }
        }
      end
    end

    remote_person_record  = JSON.parse(RestClient.post(link, demographics_hash.to_json, :content_type => "application/json"))

    if SETTINGS['remote_dde_status'].to_s == "true"
      child_national_id = remote_person_record['npid']
    else
      child_national_id = remote_person_record['person']['patient']['identifiers']['National id'].inspect
    end

    child_id = @person.person_id
    child_identifier_type_id = PersonIdentifierType.find_by_name('Barcode Number').person_identifier_type_id

    PersonIdentifier.create(
        person_id: child_id,
        person_identifier_type_id: child_identifier_type_id,
        value: child_national_id
    )

    #To be contued
    if @person.present? && SETTINGS['potential_search']
      SimpleElasticSearch.add(person_for_elastic_search(@person,params))
    else

    end

  end
end
