class MaternityController < ApplicationController
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
