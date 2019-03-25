class PersonController < ApplicationController
  def index

    @icoFolder = icoFolder("icoFolder")
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @targeturl = "/logout"
    @targettext = "Logout"

    render :layout => 'facility'
  end

  def get_sync_status
    sync_progress  = '<span color: red !important>Sync Status: Offline</span>'
    @database = YAML.load_file("#{Rails.root}/config/couchdb.yml")[Rails.env]
    source    = "#{@database['host']}:#{@database['port']}/#{@database['prefix']}_#{@database['suffix']}/"
    target    = "#{SETTINGS['sync_host']}/#{SETTINGS['sync_database']}/"
    data_link = "curl -s -X GET #{@database['protocol']}://#{@database['username']}:#{@database['password']}@#{@database['host']}:#{@database['port']}/_active_tasks"

    tasks     = JSON.parse(`#{data_link}`) rescue {}
    tasks.each do |task|
      task['target'] = task['target'].gsub(/localhost|127\.0\.0\.1/, '0.0.0.0')
      task['source'] = task['source'].gsub(/localhost|127\.0\.0\.1/, '0.0.0.0')
      target = target.gsub(/localhost|127\.0\.0\.1/, '0.0.0.0')
      source = source.gsub(/localhost|127\.0\.0\.1/, '0.0.0.0')

      next if task['type'] != 'replication'
      next if task['source'].split("@").last.strip != source.strip
      next if task['target'].split("@").last.strip != target.strip

      sync_progress = "Sync Status: #{task['progress']}%"
    end

    render text: sync_progress
  end

  def loc(id, tag=nil)
    tag_id = LocationTag.where(name: tag).last.id rescue nil
    result = nil
    if tag_id.blank?
      result = Location.find(id).name rescue nil
    else
      tagmap = LocationTagMap.where(location_tag_id: tag_id, location_id: id).last rescue nil
      if tagmap
        result = Location.find(tagmap.location_id).name rescue nil
      end
    end

    result
  end


  def show

    if params[:next_path].blank?
      @targeturl = request.referrer
    else
      @targeturl = params[:next_path]
    end

    @status = PersonRecordStatus.status(params[:id])

    if ["DC-POTENTIAL DUPLICATE","FC-POTENTIAL DUPLICATE","FC-EXACT DUPLICATE","DC-DUPLICATE"].include? @status
        redirect_to "/potential/duplicate/#{params[:id]}?next_path=/view_duplicates&index=0" and return
    end

    if ["DC-AMEND", "DC-AMEND-REJECTED"].include? @status
      redirect_to "/person/ammend_case?id=#{params[:id]}&next_path=/view_printed_cases" and return
    end

    @section = "View Record"

    @person = Person.find(params[:id])
    @core_person = CorePerson.find(params[:id])

    #New Variables

    @birth_details = PersonBirthDetail.where(person_id: @core_person.person_id).last
    @name = @person.person_names.last
    @address = @person.addresses.last

    @mother_person = @person.mother
    @mother_address = @mother_person.addresses.last rescue nil
    @mother_name = @mother_person.person_names.last rescue nil

    @father_person = @person.father
    @father_address = @father_person.addresses.last rescue nil
    @father_name = @father_person.person_names.last rescue nil

    @informant_person = @person.informant rescue nil
    @informant_address = @informant_person.addresses.last rescue nil
    @informant_name = @informant_person.person_names.last rescue nil

    @comments = PersonRecordStatus.where(" person_id = #{@person.id} AND COALESCE(comments, '') != '' ")
    days_gone = ((@birth_details.acknowledgement_of_receipt_date.to_date rescue Date.today) - @person.birthdate.to_date).to_i rescue 0
    @delayed =  days_gone > 42 ? "Yes" : "No"
    location = Location.find(SETTINGS['location_id'])
    facility_code = location.code
    birth_loc = Location.find(@birth_details.birth_location_id)
    district = Location.find(@birth_details.district_of_birth)

    birth_location = birth_loc.name rescue nil

    @place_of_birth = birth_loc.name rescue nil

    if birth_location == 'Other' && @birth_details.other_birth_location.present?
      @birth_details.other_birth_location
    end

    @place_of_birth = @birth_details.other_birth_location if @place_of_birth.blank?

    @status = PersonRecordStatus.status(@person.id)


    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, [@status])
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)

    informant_rel = (!@birth_details.informant_relationship_to_person.blank? ?
        @birth_details.informant_relationship_to_person : @birth_details.other_informant_relationship_to_person) rescue nil

    if @mother_person.present?
        mother_birth_date = @mother_person.birthdate.present? && @mother_person.birthdate.to_date.strftime('%Y-%m-%d') =='1900-01-01' ? 'N/A':  @mother_person.birthdate.to_date.strftime('%d/%b/%Y') rescue nil
    else
        mother_birth_date = nil
    end

    if @father_person.present?
        father_birth_date = @father_person.birthdate.present? && @father_person.birthdate.to_date.strftime('%Y-%m-%d') =='1900-01-01' ? 'N/A':  @father_person.birthdate.to_date.strftime('%d/%b/%Y') rescue nil
    else
        father_birth_date = nil
    end

    @record = {
        "Details of Child" => [
            {
                "Birth Entry Number" => "#{@birth_details.ben rescue nil}",
                "Birth Registration Number" => "#{@birth_details.brn  rescue nil}"
            },
            {
                ["First Name", "mandatory"] => "#{@name.first_name rescue nil}",
                "Other Name" => "#{@name.middle_name rescue nil}",
                ["Surname", "mandatory"] => "#{@name.last_name rescue nil}"
            },
            {
                ["Date of birth", "mandatory"] => "#{@person.birthdate.to_date.strftime('%d/%b/%Y') rescue nil}",
                ["Sex", "mandatory"] => "#{(@person.gender == 'F' ? 'Female' : 'Male')}",
                "Place of birth" => "#{loc(@birth_details.place_of_birth, 'Place of Birth')}"
            },
            {
                "Name of Hospital" => "#{loc(@birth_details.birth_location_id, 'Health Facility')}",
                "Other Details" => "#{@birth_details.other_birth_location}",
                "Address" => "#{@child.birth_address rescue nil}"
            },
            {
                "District" => "#{district.name}",
                "T/A" => "#{birth_loc.ta}",
                "Village" => "#{birth_loc.village rescue nil}"
            },
            {
                "Birth weight (kg)" => "#{@birth_details.birth_weight rescue nil}",
                "Type of birth" => "#{@birth_details.birth_type.name rescue nil}",
                "Other birth specified" => "#{@birth_details.other_type_of_birth rescue nil}"
            },
            {
                "Are the parents married to each other?" => "#{(@birth_details.parents_married_to_each_other.to_s == '1' ? 'Yes' : 'No') rescue nil}",
                "If yes, date of marriage" => "#{@birth_details.date_of_marriage.to_date.strftime('%d/%b/%Y')  rescue nil}"
            },

            {
                "Court Order Attached?" => "#{(@birth_details.court_order_attached.to_s == "1" ? 'Yes' : 'No') rescue nil}",
                "Parents Signed?" => "#{(@birth_details.parents_signed == "1" ? 'Yes' : 'No') rescue nil}",
                "Record Complete?" => (@birth_details.record_complete? rescue false) ? "Yes" : "No"
            },
            {
                "Place where birth was recorded" => "#{loc(@birth_details.location_created_at)}",
                "Record Status" => "#{@status}",
                "Child/Person Type" => "#{@birth_details.reg_type.name}"
            }
        ],
        "Details of Child's Mother" => [
            {
                ["First Name", "mandatory"] => "#{@mother_name.first_name rescue nil}",
                "Other Name" => "#{@mother_name.middle_name rescue nil}",
                ["Maiden Surname", "mandatory"] => "#{@mother_name.last_name rescue nil}"
            },
            {
                "Date of birth" => "#{mother_birth_date}",
                "Nationality" => "#{@mother_person.citizenship rescue nil}",
                "ID Number" => "#{@mother_person.id_number rescue nil}"
            },
            {
                "Physical Residential Address, District" => "#{loc(@mother_address.current_district, 'District') rescue nil}",
                "T/A" => "#{loc(@mother_address.current_ta, 'Traditional Authority') rescue nil}",
                "Village/Town" => "#{loc(@mother_address.current_village, 'Village') rescue nil}"
            },
            {
                "Home Address, District" => "#{loc(@mother_address.home_district, 'District') rescue nil}",
                "T/A" => "#{loc(@mother_address.home_ta, 'Traditional Authority') rescue nil}",
                "Village/Town" => "#{loc(@mother_address.home_village, 'Village') rescue nil}"
            },
            {
                "Gestation age at birth in weeks" => "#{@birth_details.gestation_at_birth rescue nil}",
                "Number of prenatal visits" => "#{@birth_details.number_of_prenatal_visits rescue nil}",
                "Month of pregnancy prenatal care started" => "#{@birth_details.month_prenatal_care_started rescue nil}"
            },
            {
                "Mode of delivery" => "#{@birth_details.mode_of_delivery.name rescue nil}",
                "Number of children born to the mother, including this child" => "#{@birth_details.number_of_children_born_alive_inclusive rescue nil}",
                "Number of children born to the mother, and still living" => "#{@birth_details.number_of_children_born_still_alive rescue nil}"
            },
            {
                "Level of education" => "#{@birth_details.level_of_education rescue nil}"
            }
        ],
        "Details of Child's Father" => [
            {
                "First Name" => "#{@father_name.first_name rescue nil}",
                "Other Name" => "#{@father_name.middle_name rescue nil}",
                "Surname" => "#{@father_name.last_name rescue nil}"
            },
            {
                "Date of birth" => "#{father_birth_date}",
                "Nationality" => "#{@father_person.citizenship rescue nil}",
                "ID Number" => "#{@father_person.id_number rescue nil}"
            },
            {
                "Physical Residential Address, District" => "#{loc(@father_address.current_district, 'District') rescue nil}",
                "T/A" => "#{loc(@father_address.current_ta, 'Traditional Authority') rescue nil}",
                "Village/Town" => "#{loc(@father_address.current_village, 'Village') rescue nil}"
            },
            {
                "Home Address, District" => "#{loc(@father_address.home_district, 'District') rescue nil}",
                "T/A" => "#{loc(@father_address.home_ta, 'Traditional Authority') rescue nil}",
                "Village/Town" => "#{loc(@father_address.home_village, 'Village') rescue nil}"
            }
        ],
        "Details of Child's Informant" => [
            {
                "First Name" => "#{@informant_name.first_name rescue nil}",
                "Other Name" => "#{@informant_name.middle_name rescue nil}",
                "Family Name" => "#{@informant_name.last_name rescue nil}"
            },
            {
                "Relationship to child" => informant_rel,
                "ID Number" => "#{@informant_person.id_number rescue ""}"
            },
            {
                "Physical Address, District" => "#{loc(@informant_address.current_district, 'District') rescue nil}",
                "T/A" => "#{loc(@informant_address.current_ta, 'Traditional Authority') rescue nil}",
                "Village/Town" => "#{loc(@informant_address.current_village, 'Village') rescue nil}"
            },
            {
                "Postal Address" => "#{@informant_address.address_line_1 rescue nil}",
                "" => "#{@informant_address.address_line_2 rescue nil}",
                "City" => "#{@informant_address.city rescue nil}"
            },
            {
                "Phone Number" => "#{@informant_person.get_attribute('Cell Phone Number') rescue nil}",
                "Informant Signed?" => "#{(@birth_details.form_signed == 1 ? 'Yes' : 'No')}"
            },
            {
                "Date Reported" => "#{@birth_details.date_reported.to_date.strftime('%d/%b/%Y') rescue ""}",
                "Date of Registration" => "#{@birth_details.date_registered.to_date.strftime('%d/%b/%Y') rescue ""}",
                ["Delayed Registration", "sub"] => "#{@delayed}"
            }
        ]
    }

    @trace_data = PersonRecordStatus.trace_data(@person.id)

    @summaryHash = {

        "Child Name" => @person.name,
        "Child Gender" => ({'M' => 'Male', 'F' => 'Female'}[@person.gender.strip.split('')[0]] rescue @person.gender),
        "Child Date of Birth" => @person.birthdate.to_date.strftime("%d/%b/%Y"),
        "Place of Birth" => "#{Location.find(@birth_details.birth_location_id).name rescue nil}",
        "Child's Mother " => (@mother_person.name rescue nil),
        "Mother Nationality " => (@mother_person.citizenship rescue "N/A"),
        "Child's Father" =>  (@father_person.name rescue nil),
        "Father Nationality" =>  (@father_person.citizenship rescue "N/A"),
        "Parents Married" => (@birth_details.parents_married_to_each_other.to_s == '1' ? 'Yes' : 'No'),
        "Court order attached" => (@birth_details.court_order_attached.to_s == '1' ? 'Yes' : 'No'),
        "Parents signed?" => ((@birth_details.parents_signed rescue -1).to_s == '1' ? 'Yes' : 'No'),
        "Delayed Registration" => @delayed
    }

    if  (BirthRegistrationType.find(@person_details.birth_registration_type_id).name.upcase rescue nil) == 'ADOPTED'
      @summaryHash["Adoptive Mother"] = nil
      @summaryHash[ "Adoptive Father"] = nil
      @summaryHash["Adoption Court Order"] = nil
    end
    @results = []
    if ['FC-POTENTIAL DUPLICATE','DC-POTENTIAL DUPLICATE','DC-DUPLICATE'].include? @status && @folders.include?("Manage Duplicates")
        redirect_to "/potential/duplicate/#{@person.id}?index=0"
    else
        if @person.present? && SETTINGS['potential_search'] && SETTINGS['application_mode'] =="DC"

          person = {}
          person["id"] = @person.person_id.to_s
          person["first_name"]= @name.first_name rescue ''
          person["last_name"] =  @name.last_name rescue ''
          person["middle_name"] = @name.middle_name rescue ''
          person["gender"] = (@person.gender == 'F' ? 'Female' : 'Male')
          person["birthdate"]= @person.birthdate.to_date.strftime('%Y-%m-%d')
          person["birthdate_estimated"] = @person.birthdate_estimated
          person["nationality"]=  @mother_person.citizenship rescue nil
          person["place_of_birth"] = @place_of_birth

          if  birth_loc.district.present?
            person["district"] = birth_loc.district
          else
            person["district"] = "Lilongwe"
          end

          person["mother_first_name"]= @mother_name.first_name rescue ''
          person["mother_last_name"] =  @mother_name.last_name  rescue ''
          person["mother_middle_name"] = @mother_name.middle_name rescue ''

          person["mother_home_district"] = Location.find(@mother_person.addresses.last.home_district).name rescue nil
          person["mother_home_ta"] = Location.find(@mother_person.addresses.last.home_ta).name rescue nil
          person["mother_home_village"] = Location.find(@mother_person.addresses.last.home_village).name rescue nil

          person["mother_current_district"] = Location.find(@mother_person.addresses.last.current_district).name rescue nil
          person["mother_current_ta"] = Location.find(@mother_person.addresses.last.current_ta).name rescue nil
          person["mother_current_village"] = Location.find(@mother_person.addresses.last.current_village).name rescue nil


          person["father_first_name"]= @father_name.first_name  rescue ''
          person["father_last_name"] =  @father_name.last_name  rescue ''
          person["father_middle_name"] = @father_name.middle_name  rescue ''

          person["father_home_district"] = Location.find(@father_person.addresses.last.home_district).name rescue nil
          person["father_home_ta"] = Location.find(@father_person.addresses.last.home_ta).name rescue nil
          person["father_home_village"] = Location.find(@father_person.addresses.last.home_village).name rescue nil

          person["father_current_district"] = Location.find(@father_person.addresses.last.current_district).name rescue nil
          person["father_current_ta"] = Location.find(@father_person.addresses.last.current_ta).name rescue nil
          person["father_current_village"] = Location.find(@father_person.addresses.last.current_village).name rescue nil

          SimpleElasticSearch.add(person)

          if @status == "DC-ACTIVE"

            @results = []
            @exact = false
            duplicates = []
            duplicates = SimpleElasticSearch.query_duplicate_coded(person,99.4)

            if duplicates.blank?
              duplicates = SimpleElasticSearch.query_duplicate_coded(person,SETTINGS['duplicate_precision'])
            else
              @exact = true
            end


            duplicates.each do |dup|
                next if DuplicateRecord.where(person_id: person['id']).present?
                @results << dup if PotentialDuplicate.where(person_id: dup['_id']).blank?
            end


            if @results.present? && !@birth_details.birth_type.name.to_s.downcase.include?("twin")
               potential_duplicate = PotentialDuplicate.create(person_id: @person.person_id,created_at: (Time.now))
               if potential_duplicate.present?
                     @results.each do |result|
                        potential_duplicate.create_duplicate(result["_id"])
                     end
               end
               #PersonRecordStatus.new_record_state(@person.person_id, "HQ-POTENTIAL DUPLICATE-TBA", "System mark record as potential duplicate")
               if @exact
                 @status = "DC-DUPLICATE"
               else
                 @status = "DC-POTENTIAL DUPLICATE"
               end
               #PersonRecordStatus.status(@person.id)

            end
          end
        else
             @results = []
        end
        render :layout => "facility"
    end

  end

  def records

   if application_mode == 'Facility'
      @states = ["DC-Complete"]
   else
      @states = ["DC-Active"]
   end


    @section = "New Cases"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)

    #@records = PersonService.query_for_display(@states)

    render :template => "person/records", :layout => "data_table"

  end

  def new

    if  SETTINGS["application_mode"] == "FC"
        @current_district = Location.find(Location.find(SETTINGS["location_id"]).parent_location).name
    else
        @current_district = Location.find(SETTINGS['location_id']).name rescue nil
    end

    $prev_child_id = params[:id]


    if params[:id].blank?

      @person = PersonName.new
      @person_details = PersonBirthDetail.new
      @type_of_birth = "Single"
      @section = "New Person"

    else

      @person = Person.find(params[:id])

      @person_details = PersonBirthDetail.find_by_person_id(params[:id])


      @person_name = PersonName.find_by_person_id(params[:id])

      @person_mother_name = @person.mother.person_names.first rescue nil

      @person_father_name = @person.father.person_names.first rescue nil

      if PersonBirthDetail.find_by_person_id(params[:id]).type_of_birth == 2
         @type_of_birth = "Second Twin"
      elsif PersonBirthDetail.find_by_person_id(params[:id]).type_of_birth == 4
         @type_of_birth = "Second Triplet"
      elsif PersonBirthDetail.find_by_person_id(params[:id]).type_of_birth == 5
         @type_of_birth = "Third Triplet"
      end


    end

     render :layout => "touch_split"
  end

  def new_split

    if  SETTINGS["application_mode"] == "FC"
      @current_district = Location.find(Location.find(SETTINGS["location_id"]).parent_location).name
    else
      @current_district = Location.find(SETTINGS['location_id']).name rescue nil
    end

    $prev_child_id = params[:id]


    if params[:id].blank?

      @person = PersonName.new
      @person_details = PersonBirthDetail.new
      @type_of_birth = "Single"
      @section = "New Person"

    else

      @person = Person.find(params[:id])

      @person_details = PersonBirthDetail.find_by_person_id(params[:id])


      @person_name = PersonName.find_by_person_id(params[:id])

      @person_mother_name = @person.mother.person_names.first rescue nil

      @person_father_name = @person.father.person_names.first rescue nil

      if PersonBirthDetail.find_by_person_id(params[:id]).type_of_birth == 2
        @type_of_birth = "Second Twin"
      elsif PersonBirthDetail.find_by_person_id(params[:id]).type_of_birth == 4
        @type_of_birth = "Second Triplet"
      elsif PersonBirthDetail.find_by_person_id(params[:id]).type_of_birth == 5
        @type_of_birth = "Third Triplet"
      end
    end

    render :layout => "touch"
  end

  def create
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

    #print barcode
    print_and_redirect("/person/child_id_label?child_id=#{child_id}", '/view_cases') and return

    if ["First Twin", "First Triplet", "Second Triplet"].include?(type_of_birth.strip)

      redirect_to "/person/new?id=#{@person.id}"

    else

       if application_mode == 'Facility'

          redirect_to '/view_cases'

        else

          redirect_to '/view_cases'

        end
    end

  end

  # added for printing (added for eVR)

  # reprinting child label
  def reprint_child_id_label
    child_id = params[:child_id]
    print_and_redirect("/person/child_id_label?child_id=#{child_id}", '/view_cases') and return
  end

  def child_id_label
    print_string = child_label(params[:child_id])

    send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:child_id]}#{rand(10000)}.lbl", :disposition => "inline")
  end

  def child_label(child_id)

    @child = Person.find(child_id)

    @child_national_id = PersonIdentifier.find_by_person_id(@child.id).value.gsub('"','') rescue nil
    sex =  @child.gender.match(/F/i) ? "(F)" : "(M)"

    place_of_birth = @child.hospital_of_birth  rescue ""
    place_of_birth = @child.place_of_birth rescue "" if place_of_birth.blank?

    label = ZebraPrinter::StandardLabel.new
    label.font_size = 2
    label.font_horizontal_multiplier = 1
    label.font_vertical_multiplier = 1
    label.left_margin = 50
    label.draw_barcode(50,180,0,1,5,15,120,false,"#{@child_national_id}")
    label.draw_multi_text("ID Number: #{@child_national_id}")
    label.draw_multi_text("Child: #{@child.first_name + ' ' + @child.last_name} #{sex}")
    label.draw_multi_text("DOB: #{@child.birthdate}")
    label.draw_multi_text("Birth Place: #{place_of_birth + '/' + @child.place_of_birth}")
    label.draw_multi_text("Mother: #{(@child.mother.first_name rescue '') + ' ' + (@child.mother.last_name rescue '')}")
    label.draw_multi_text("Child Informant: #{(@child.informant.first_name rescue '') + ' ' + (@child.informant.last_name rescue '')}")
    label.draw_multi_text("Date of Reporting: #{@child.acknowledgement_of_receipt_date.strftime('%d/%B/%Y') rescue ''}")
    label.print(1)

  end
  #-------------------------------

  def update_person

    @person = Person.find(params[:id])

    @core_person = CorePerson.find(params[:id])

    @person_details = PersonBirthDetail.find_by_person_id(params[:id])

    @person_name = PersonName.find_by_person_id(params[:id])

    @person_mother_name = @person.mother.person_names.first rescue nil

    @person_father_name = @person.father.person_names.first rescue nil

    #New Variables

    @birth_details = PersonBirthDetail.where(person_id: @core_person.person_id).last
    @name = @person.person_names.last
    @address = @person.addresses.last

    @mother_person = @person.mother
    @mother_address = @mother_person.addresses.last rescue nil
    @mother_name = @mother_person.person_names.last rescue nil

    @father_person = @person.father
    @father_address = @father_person.addresses.last rescue nil
    @father_name = @father_person.person_names.last rescue nil

    @informant_person = @person.informant rescue nil
    @informant_address = @informant_person.addresses.last rescue nil
    @informant_name = @informant_person.person_names.last rescue nil

    @comments = PersonRecordStatus.where(" person_id = #{@person.id} AND COALESCE(comments, '') != '' ")
    days_gone = ((@birth_details.acknowledgement_of_receipt_date.to_date rescue Date.today) - @person.birthdate.to_date).to_i rescue 0
    @delayed =  days_gone > 42 ? "Yes" : "No"
    location = Location.find(SETTINGS['location_id'])
    facility_code = location.code
    birth_loc = Location.find(@birth_details.birth_location_id)

    birth_location = birth_loc.name rescue nil

    @place_of_birth = birth_loc.name rescue nil

    if birth_location == 'Other' && @birth_details.other_birth_location.present?
      @birth_details.other_birth_location
    end

    @place_of_birth = @birth_details.other_birth_location if @place_of_birth.blank?

    #raise PersonBirthDetail.find_by_person_id(params[:id]).birth_place.inspect

    if PersonBirthDetail.find_by_person_id(params[:id]).type_of_birth == 2
        @type_of_birth = "Second Twin"
    elsif PersonBirthDetail.find_by_person_id(params[:id]).type_of_birth == 4
        @type_of_birth = "Second Triplet"
    elsif PersonBirthDetail.find_by_person_id(params[:id]).type_of_birth == 5
        @type_of_birth = "Third Triplet"
    end

    @field = params['field']

    @section = "Update Record"

    render :layout => "touch"
  end

  def update

    if ["child_first_name","child_last_name","child_middle_name"].include?(params[:field])
      person_name = PersonName.find_by_person_id(params[:id])
      if params[:person][:first_name] != person_name.first_name  || params[:person][:last_name] != person_name.last_name || params[:person][:middle_name] != person_name.middle_name
        person_name.update_attributes(voided: true, void_reason: 'General edit')
        person_name = PersonName.create(person_id: params[:id],
              first_name: params[:person][:first_name],
              middle_name: params[:person][:middle_name],
              last_name: params[:person][:last_name])

      end
      redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
    end

    if ["child_birthdate","child_gender"].include?(params[:field])
      person = Person.find(params[:id])
      if params[:person][:gender][0] != person.gender
        person.gender = params[:person][:gender][0]
        person.save
      end

      if params[:person][:birthdate].to_date.to_s != person.birthdate.to_date.to_s
        person.birthdate = params[:person][:birthdate].to_date.to_s
        person.save
      end
       redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
    end

    if ["birth_details_hospital_of_birth","birth_details_place_of_birth","birth_details_other_details","birth_location_district","birth_location_ta","birth_location_village"].include?(params[:field])
      if params[:person][:place_of_birth] == 'Home'
        district_id = Location.locate_id_by_tag(params[:person][:birth_district], 'District')
        ta_id = Location.locate_id(params[:person][:birth_ta], 'Traditional Authority', district_id)
        village_id = Location.locate_id(params[:person][:birth_village], 'Village', ta_id)
        location_id = [village_id, ta_id, district_id].compact.first #Notice the order

        birth_details = PersonBirthDetail.where(person_id: params[:id]).last
        birth_details.birth_location_id = location_id
        birth_details.save

      elsif params[:person][:place_of_birth] == 'Hospital'
        map =  {'Mzuzu City' => 'Mzimba',
                'Lilongwe City' => 'Lilongwe',
                'Zomba City' => 'Zomba',
                'Blantyre City' => 'Blantyre'}

        person[:birth_district] = map[params[:person][:birth_district]] if params[:person][:birth_district].match(/City$/)

        district_id = Location.locate_id_by_tag(params[:person][:birth_district], 'District')
        location_id = Location.locate_id(params[:person][:hospital_of_birth], 'Health Facility', district_id)

        location_id = [location_id, district_id].compact.first

        birth_details = PersonBirthDetail.where(person_id: params[:id]).last
        birth_details.birth_location_id = location_id
        birth_details.save

      else #Other
        location_id = Location.where(name: 'Other').last.id #Location.locate_id_by_tag(person[:birth_district], 'District')
        other_place_of_birth = params[:person][:other_birth_place_details]

        birth_details = PersonBirthDetail.where(person_id: params[:id]).last
        birth_details.birth_location_id = location_id
        birth_details.other_birth_location = other_birth_location
        birth_details.save
      end
      redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
      #raise params.inspect
    end

    if ["birth_details_birth_weight","birth_details_birth_type","birth_details_other_birth_type","birth_details_gestation_at_birth","birth_details_number_of_prenatal_visits", "birth_details_month_prenatal_care_started","birth_details_mode_of_delivery"].include?(params[:field])

      birth_details = PersonBirthDetail.where(person_id: params[:id]).last

      if params[:person][:birth_weight].present? && birth_details.birth_weight.to_i != params[:person][:birth_weight].to_i
        birth_details.birth_weight = params[:person][:birth_weight]
      end


      if params[:person][:type_of_birth].present?
        person_type_of_birth = PersonTypeOfBirth.where(name: params[:person][:type_of_birth]).last.person_type_of_birth_id
        birth_details.type_of_birth = person_type_of_birth
        if params[:person][:type_of_birth] == "Other"
          birth_details.other_type_of_birth = params[:person][:other_type_of_birth]
        end
      end

      if params[:person][:gestation_at_birth].present?
        birth_details.gestation_at_birth = params[:person][:gestation_at_birth]
      end

      if params[:person][:number_of_prenatal_visits].present?
        birth_details.number_of_prenatal_visits = params[:person][:number_of_prenatal_visits]
      end

      if params[:person][:month_prenatal_care_started].present?
        birth_details.month_prenatal_care_started = params[:person][:month_prenatal_care_started]
      end

      if params[:person][:mode_of_delivery].present?
        delivery_mode = ModeOfDelivery.find_by_name(params[:person][:mode_of_delivery]).id
        birth_details.mode_of_delivery_id = delivery_mode
      end

      if birth_details.save
        redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
      end
    end

    if ["birth_details_number_of_children_born_alive_inclusive","birth_details_number_of_children_born_still_alive","birth_details_level_of_education"].include?(params[:field])
        birth_details = PersonBirthDetail.where(person_id: params[:id]).last

        if params[:person][:number_of_children_born_still_alive].present?
           birth_details.number_of_children_born_still_alive = params[:person][:number_of_children_born_still_alive]
        end

        if params[:person][:number_of_children_born_alive_inclusive].present?
          birth_details.number_of_children_born_alive_inclusive = params[:person][:number_of_children_born_alive_inclusive]
        end

        if params[:person][:level_of_education].present?
            level_of_education = LevelOfEducation.find_by_name(params[:person][:level_of_education]).id
            birth_details.level_of_education_id = level_of_education
        end

        if birth_details.save
          redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
        end
    end

    if ["birth_details_court_order_attached","birth_details_parents_signed","birth_details_parents_married_to_each_other","birth_details_date_of_marriage"  ].include?(params[:field])
      birth_details = PersonBirthDetail.where(person_id: params[:id]).last
      if params[:person][:parents_married_to_each_other].present?
          birth_details.parents_married_to_each_other = (params[:person][:parents_married_to_each_other] == "Yes" ? 1 : 0)
          if params[:person][:parents_married_to_each_other] == "Yes"
            birth_details.court_order_attached = 0
            birth_details.parents_signed = 0
          end
      end

      if params[:person][:date_of_marriage].present?
          if params[:person][:parents_married_to_each_other] == "No"
            birth_details.date_of_marriage =  nil
          else
            birth_details.date_of_marriage = params[:person][:date_of_marriage].to_date.to_s rescue nil
          end

      end

      if params[:person][:court_order_attached].present?
        birth_details.court_order_attached = (params[:person][:court_order_attached] == "Yes" ? 1 : 0)
      end

      if params[:person][:parents_signed].present?
        birth_details.parents_signed = (params[:person][:parents_signed] == "Yes" ? 1 : 0)
      end

      if birth_details.save
        redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
      end
    end

    if ["mother_last_name","mother_first_name", "mother_middle_name", "mother_id_number","mother_birth_date"].include?(params[:field])
          person_mother = Person.find(params[:id]).mother
          person_mother_name = PersonName.find_by_person_id(person_mother.id)
          if params[:person][:mother][:first_name] != person_mother_name.first_name  || params[:person][:mother][:last_name] != person_mother_name.last_name || params[:person][:mother][:middle_name] != person_mother_name.middle_name
            person_mother_name.update_attributes(voided: true, void_reason: 'General edit')
            person_mother_name = PersonName.create(person_id: person_mother.id,
                  first_name: params[:person][:mother][:first_name],
                  middle_name: params[:person][:mother][:middle_name],
                  last_name: params[:person][:mother][:last_name])
          end

          if params[:person][:mother][:id_number].present?
              identifier_type = PersonIdentifierType.find_by_name("National ID Number").id

              mother_identifier = PersonIdentifier.where(person_id: person_mother.id, person_identifier_type_id: identifier_type).last

              if mother_identifier.present?
                 mother_identifier.update_attributes(value: params[:person][:mother][:id_number])
              else
                PersonIdentifier.create(
                          person_id: mother_person.person_id,
                          person_identifier_type_id: (PersonIdentifierType.find_by_name("National ID Number").id),
                          value: params[:person][:mother][:id_number]
                  )
              end
          end

          if params[:person][:mother][:birthdate].present?
              person_mother.birthdate = params[:person][:mother][:birthdate].to_date.to_s
              person_mother.save
          end

          redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
    end


    if ["mother_address_current_district","mother_address_current_ta", "mother_address_current_village","mother_citizenship"].include?(params[:field])
        person_mother = Person.find(params[:id]).mother
        person_address = PersonAddress.find_by_person_id(person_mother.id)
        if params[:person][:mother][:citizenship].present?
          person_address.citizenship = Location.find_by_country(params[:person][:mother][:citizenship]).id
        end
        if params[:person][:mother][:residential_country].present?
          person_address.residential_country = Location.find_by_name(params[:person][:mother][:residential_country]).id
        end
        if params[:person][:mother][:current_district].present?
          person_address.current_district  = Location.find_by_name(params[:person][:mother][:current_district]).id
        end
        if params[:person][:mother][:current_ta].present?
          person_address.current_ta = Location.find_by_name(params[:person][:mother][:current_district]).id
        end
        if params[:person][:mother][:current_village].present?
          person_address.current_village = Location.find_by_name(params[:person][:mother][:current_village]).id
        end
        if person_address.save
          redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
        end
    end

    if ["mother_address_home_district","mother_address_home_ta", "mother_address_home_village"].include?(params[:field])
        person_mother = Person.find(params[:id]).mother
        person_address = PersonAddress.find_by_person_id(person_mother.id)

        if params[:person][:mother][:home_district].present?
          person_address.home_district  = Location.find_by_name(params[:person][:mother][:home_district]).id
        end
        if params[:person][:mother][:home_ta].present?
          person_address.home_ta = Location.find_by_name(params[:person][:mother][:home_ta]).id
        end
        if params[:person][:mother][:home_village].present?
          person_address.home_village = Location.find_by_name(params[:person][:mother][:home_village]).id
        end
        if person_address.save
          redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
        end
    end

    if ["father_last_name","father_first_name","father_middle_name", "father_id_number","mother_birth_date"].include?(params[:field])
          person_father = Person.find(params[:id]).father
          person_father_name = PersonName.find_by_person_id(person_father.id)
          if params[:person][:father][:first_name] != person_father_name.first_name  || params[:person][:father][:last_name] != person_father_name.last_name || params[:person][:father][:middle_name] != person_father_name.middle_name
            person_father_name.update_attributes(voided: true, void_reason: 'General edit')
            person_father_name = PersonName.create(person_id: person_father.id,
                  first_name: params[:person][:father][:first_name],
                  middle_name: params[:person][:father][:middle_name],
                  last_name: params[:person][:father][:last_name])
          end

          if params[:person][:father][:id_number].present?
              identifier_type = PersonIdentifierType.find_by_name("National ID Number").id

              father_identifier = PersonIdentifier.where(person_id: person_father.id, person_identifier_type_id: identifier_type).last

              if father_identifier.present?
                 father_identifier.update_attributes(value: params[:person][:mother][:id_number])
              else
                PersonIdentifier.create(
                          person_id: mother_person.person_id,
                          person_identifier_type_id: (PersonIdentifierType.find_by_name("National ID Number").id),
                          value: params[:person][:father][:id_number]
                  )
              end
          end

          if params[:person][:father][:birthdate].present?
              person_father.birthdate = params[:person][:father][:birthdate].to_date.to_s
              person_father.save
          end
          redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
    end

    if ["father_address_current_district","father_address_current_ta","father_address_current_village","father_citizenship"].include?(params[:field])
        person_father = Person.find(params[:id]).father
        person_address = PersonAddress.find_by_person_id(person_father.id)
        if params[:person][:father][:citizenship].present?
          person_address.citizenship = Location.find_by_country(params[:person][:father][:citizenship]).id
        end
        if params[:person][:father][:residential_country].present?
          person_address.residential_country = Location.find_by_name(params[:person][:father][:residential_country]).id
        end
        if params[:person][:father][:current_district].present?
          person_address.current_district  = Location.find_by_name(params[:person][:father][:current_district]).id
        end
        if params[:person][:father][:current_ta].present?
          person_address.current_ta = Location.find_by_name(params[:person][:father][:current_district]).id
        end
        if params[:person][:father][:current_village].present?
          person_address.current_village = Location.find_by_name(params[:person][:father][:current_village]).id
        end
        if person_address.save
          redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
        end
    end

    if ["father_address_home_district","father_address_home_ta","father_address_home_village"].include?(params[:field])
        person_father = Person.find(params[:id]).father
        person_address = PersonAddress.find_by_person_id(person_father.id)

        if params[:person][:father][:home_district].present?
          person_address.home_district  = Location.find_by_name(params[:person][:father][:home_district]).id
        end
        if params[:person][:father][:home_ta].present?
          person_address.home_ta = Location.find_by_name(params[:person][:father][:home_ta]).id
        end
        if params[:person][:father][:home_village].present?
          person_address.home_village = Location.find_by_name(params[:person][:father][:home_village]).id
        end
        if person_address.save
          redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
        end
    end

    if ["informant_last_name","informant_first_name","informant_middle_name", "informant_id_number", "informant_relationship"].include?(params[:field])
          person_informant = Person.find(params[:id]).informant
          person_informant_name = PersonName.find_by_person_id(person_informant.id)
          if params[:person][:informant][:first_name] != person_informant_name.first_name  || params[:person][:informant][:last_name] != person_informant_name.last_name || params[:person][:informant][:middle_name] != person_informant_name.middle_name
            person_informant_name.update_attributes(voided: true, void_reason: 'General edit')
            person_informant_name = PersonName.create(person_id: person_informant.id,
                  first_name: params[:person][:informant][:first_name],
                  middle_name: params[:person][:informant][:middle_name],
                  last_name: params[:person][:informant][:last_name])
          end

          if params[:person][:informant][:id_number].present?
              identifier_type = PersonIdentifierType.find_by_name("National ID Number").id

              informant_identifier = PersonIdentifier.where(person_id: person_father.id, person_identifier_type_id: identifier_type).last

              if father_identifier.present?
                 father_identifier.update_attributes(value: params[:person][:informant][:id_number])
              else
                PersonIdentifier.create(
                          person_id: mother_person.person_id,
                          person_identifier_type_id: (PersonIdentifierType.find_by_name("National ID Number").id),
                          value: params[:person][:informant][:id_number]
                  )
              end
          end
          redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
    end

    if ["informant_address_home_district","informant_address_home_ta","informant_address_home_village", "informant_address"].include?(params[:field])
      person_informant = Person.find(params[:id]).informant
      person_address = PersonAddress.find_by_person_id(person_informant.id)
      if params[:person][:informant][:current_district].present?
          person_address.current_district  = Location.find_by_name(params[:person][:informant][:current_district]).id
      end
      if params[:person][:informant][:current_ta].present?
          person_address.current_ta = Location.find_by_name(params[:person][:informant][:current_ta]).id
      end
      if params[:person][:informant][:current_village].present?
          person_address.current_village = Location.find_by_name(params[:person][:informant][:current_village]).id
      end
      if params[:person][:informant][:addressline1].present?
          person_address.address_line_1 = params[:person][:informant][:addressline1]
      end
      if params[:person][:informant][:addressline2].present?
         person_address.address_line_2 = params[:person][:informant][:addressline2]
      end
      if person_address.save
          redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
      end

    end

    if ["informant_cell_phone_number","birth_details_form_signed","child_acknowledgement_of_receipt_date"].include?(params[:field])

        person_informant = Person.find(params[:id]).informant
        if params[:person][:informant][:phone_number].present?
            informant_number = PersonAttribute.find_by_person_id(person_informant.id)
            if informant_number.blank?
                  PersonAttribute.create(
                      :person_id                => person_informant.id,
                      :person_attribute_type_id => PersonAttributeType.where(name: 'cell phone number').last.id,
                      :value                    => params[:person][:informant][:phone_number],
                      :voided                   => 0
                  )
            else
                informant_number.voided = 0
                informant_number.save
                PersonAttribute.create(
                      :person_id                => person_informant.id,
                      :person_attribute_type_id => PersonAttributeType.where(name: 'cell phone number').last.id,
                      :value                    => params[:person][:informant][:phone_number],
                      :voided                   => 0
                  )

            end
        end

        birth_details = PersonBirthDetail.where(person_id: params[:id]).last
        if params[:person][:form_signed].present?
          birth_details.form_signed = (params[:person][:form_signed] == "Yes" ? 1 : 0)
          birth_details.save
        end
        if params[:person][:acknowledgement_of_receipt_date].present?
          birth_details.acknowledgement_of_receipt_date = params[:person][:acknowledgement_of_receipt_date].to_date.to_s
          birth_details.save
        end
        redirect_to "/person/#{params[:id]}/edit?next_path=/view_cases" and return
    end

  end

  def person_for_elastic_search(core_person,params)
      person = {}
      person["id"] = core_person.person_id
      person["first_name"]= params[:person][:first_name]
      person["last_name"] =  params[:person][:last_name]
      person["middle_name"] = params[:person][:middle_name]
      person["gender"] = params[:person][:gender]
      person["birthdate"]= params[:person][:birthdate].to_date.strftime('%Y-%m-%d')
      person["birthdate_estimated"] = params[:person][:birthdate_estimated]

      if is_twin_or_triplet(params[:person][:type_of_birth].to_s) && params[:person][:prev_child_id].present?
         prev_child = Person.find(params[:person][:prev_child_id].to_i)
         if params[:relationship] == "opharned" || params[:relationship] == "adopted"
           mother = prev_child.adoptive_mother
         else
           mother = prev_child.mother
         end

         if mother.present?
            mother_name =  mother.person_names.first
         else
            mother_name = nil
         end

         person["mother_first_name"] = mother_name.first_name rescue ""
         person["mother_last_name"] =   mother_name.last_name rescue ""
         person["mother_middle_name"] =  mother_name.first_name rescue ""

         person["mother_home_district"] = Location.find(mother.addresses.last.home_district).name rescue nil
         person["mother_home_ta"] = Location.find(mother.addresses.last.home_ta).name rescue nil
         person["mother_home_village"] = Location.find(mother.addresses.last.home_village).name rescue nil

         person["mother_current_district"] = Location.find(mother.addresses.last.current_district).name rescue nil
         person["mother_current_ta"] = Location.find(mother.addresses.last.current_ta).name rescue nil
         person["mother_current_village"] = Location.find(mother.addresses.last.current_village).name rescue nil

         if params[:relationship] == "opharned" || params[:relationship] == "adopted"
           father = prev_child.adoptive_father
         else
           father = prev_child.father
         end

         if father.present?
            father_name =  father.person_names.first
         else
            father_name = nil
         end

         person["father_first_name"] = father_name.first_name rescue ""
         person["father_last_name"] =   father_name.last_name rescue ""
         person["father_middle_name"] = father_name.first_name rescue ""

         person["father_home_district"] = Location.find(father.addresses.last.home_district).name rescue nil
         person["father_home_ta"] = Location.find(father.addresses.last.home_ta).name rescue nil
         person["father_home_village"] = Location.find(father.addresses.last.home_village).name rescue nil

         person["father_current_district"] = Location.find(father.addresses.last.current_district).name rescue nil
         person["father_current_ta"] = Location.find(father.addresses.last.current_ta).name rescue nil
         person["father_current_village"] = Location.find(father.addresses.last.current_village).name rescue nil

         birth_details = prev_details = PersonBirthDetail.where(person_id: params[:person][:prev_child_id].to_i).first
         person["place_of_birth"] = Location.find(birth_details.place_of_birth).name
         person["district"] = Location.find(birth_details.district_of_birth).name
         person["nationality"]= Location.find(mother.addresses.first.citizenship).name rescue "Malawian"

      else

        person["place_of_birth"] = params[:person][:place_of_birth]
        person["district"] = params[:person][:birth_district]
        person["nationality"]=  params[:person][:mother][:citizenship]
        person["mother_first_name"]= params[:person][:mother][:first_name] rescue nil
        person["mother_last_name"] =  params[:person][:mother][:last_name] rescue nil
        person["mother_middle_name"] = params[:person][:mother][:middle_name] rescue nil

        person["mother_home_district"] = params[:person][:mother][:home_district] rescue nil
        person["mother_home_ta"] = params[:person][:mother][:home_ta] rescue nil
        person["mother_home_village"] = params[:person][:mother][:home_village] rescue nil

        person["mother_current_district"] = params[:person][:mother][:current_district] rescue nil
        person["mother_current_ta"] = params[:person][:mother][:current_ta] rescue nil
        person["mother_current_village"] = params[:person][:mother][:current_village] rescue nil

        person["father_first_name"]= params[:person][:father][:first_name] rescue nil
        person["father_last_name"] =  params[:person][:father][:last_name] rescue nil
        person["father_middle_name"] = params[:person][:father][:middle_name] rescue nil

        person["father_home_district"] = params[:person][:father][:home_district] rescue nil
        person["father_home_ta"] = params[:person][:father][:home_ta] rescue nil
        person["father_home_village"] = params[:person][:father][:home_village] rescue nil

        person["father_current_district"] = params[:person][:father][:current_district] rescue nil
        person["father_current_ta"] = params[:person][:father][:current_ta] rescue nil
        person["father_current_village"] = params[:person][:father][:current_village] rescue nil

      end
      return person
  end

  def is_twin_or_triplet(type_of_birth)
    if type_of_birth.include?"Second Twin"
      return true
    elsif type_of_birth.include?"Second Triplet"
      return true
    elsif type_of_birth.to_s.include? "Third Triplet"
      return true
    else
      return false
    end
  end

  def parents_married(parents_married,value)

    if parents_married == 1
        [value, "mandatory"]
    else
       return value
    end

  end

  #########################################################################
  ############### Duplicate search with elastic search ####################
 def search_similar_record

     if params[:twin_id].present?
        birthdate = Person.where(person_id: params[:twin_id]).first.birthdate.to_time.to_s.split(" ")[0]
     else
        birthdate = (params[:birthdate].to_time.to_s.split(" ")[0] rescue params[:birthdate].to_time)
     end
      person = {
                      "first_name"=>params[:first_name],
                      "last_name" => params[:last_name],
                      "middle_name" => (psimilararams[:middle_name] rescue nil),
                      "gender" => params[:gender],
                      "district" => params[:birth_district],
                      "birthdate"=> birthdate.to_date.strftime('%Y-%m-%d'),
                      "mother_last_name" => (params[:mother_last_name] rescue nil),
                      "mother_middle_name" => (params[:mother_middle_name] rescue nil),
                      "mother_first_name" => (params[:mother_first_name] rescue nil),
                      "father_last_name" => (params[:father_last_name] rescue nil),
                      "father_middle_name" => (params[:father_middle_name] rescue nil),
                      "father_last_name" => (params[:father_last_name] rescue nil)
                  }


      if SETTINGS['potential_search']
        results = duplicate_search(person, params)
      else
        results = {:response => []}
      end


      if results[:response].count == 0
        render :text => {:response => false}.to_json
      else
        render :text => results.to_json
      end

  end

  def duplicate_search(person, params)
      dupliates = SimpleElasticSearch.query_duplicate_coded(person,99.4)
      exact = false
      if dupliates.blank?
        if params[:type_of_birth] && is_twin_or_triplet(params[:type_of_birth])
          dupliates = []
        else
          if params[:relationship] == "normal" || params[:relationship] == "adopted"
              dupliates = SimpleElasticSearch.query_duplicate_coded(person,SETTINGS['duplicate_precision'])
          else
              dupliates = SimpleElasticSearch.query_duplicate_coded(person,"95")
          end
        end
      else
        exact  = true
      end
      return {:response => dupliates, :exact => exact}
  end

  def get_names
    entry = params["search"].soundex
    if params["last_name"]
      data = PersonName.find_by_sql(" SELECT last_name FROM person_name WHERE last_name LIKE '#{params[:search]}%' ORDER BY last_name LIMIT 10").map(&:last_name)
      if data.present?
        render text: data.reject{|n| n == '@@@@@'}.join("\n") and return
      else
        render text: "" and return
      end
    elsif params["first_name"]
      data = PersonName.find_by_sql(" SELECT first_name FROM person_name WHERE first_name LIKE '#{params[:search]}%' ORDER BY first_name LIMIT 10").map(&:first_name)
      if data.present?
        render text: data.reject{|n| n == '@@@@@'}.join("\n") and return
      else
        render text: "" and return
      end
    end

    render text: ''
  end

  def get_nationality
    nationality_tag = LocationTag.where(name: 'Country').first
    data = ['Malawian']
    Location.where("LENGTH(country) > 0 AND country != 'Malawian' AND country LIKE (?) AND m.location_tag_id = ?",
      "#{params[:search]}%", nationality_tag.id).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('country ASC').map do |l|
      data << l.country
    end

    if data.present?
      render text: ("<li>" + data.compact.uniq.join("</li><li>") + "</li>") and return
    else
      render text: "" and return
    end
  end

  def get_country
    nationality_tag = LocationTag.where(name: 'Country').first
    data = ['Malawi']
    Location.where("LENGTH(name) > 0 AND country != 'Malawi' AND name LIKE (?) AND m.location_tag_id = ?",
      "#{params[:search]}%", nationality_tag.id).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << l.name
    end

    if data.present?
      render text: ("<li>" + data.compact.uniq.join("</li><li>") + "</li>") and return
    else
      render text: "" and return
    end
  end

  def get_district

    cities = ["Blantyre City","Lilongwe City","Mzuzu City","Zomba City"]

    nationality_tag = LocationTag.where(name: 'District').first
    data = []
    Location.where("LENGTH(name) > 0 AND name LIKE (?) AND m.location_tag_id = ?",
      "#{params[:search]}%", nationality_tag.id).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
          if params[:exclude].present?
                next if l.name.include?(params[:exclude])
                data << l.name
          else
                data << l.name
          end
    end


    if data.present?
      render text: ("<li>" + data.compact.uniq.join("</li><li>") + "</li>") and return
    else
      render text: "" and return
    end
  end

  def get_ta
    district_name = params[:district]
    nationality_tag = LocationTag.where(name: 'Traditional Authority').first
    location_id_for_district = Location.where(name: district_name).first.id

    data = []
    Location.where("LENGTH(name) > 0 AND name LIKE (?) AND m.location_tag_id = ? AND parent_location = ?",
      "#{params[:search]}%", nationality_tag.id, location_id_for_district).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << l.name
    end

    if data.present?
      render text: ("<li>" + data.compact.uniq.join("</li><li>") + "</li>") and return
    else
      render text: "" and return
    end
  end

  def get_village
    district_name = params[:district]
    location_id_for_district = Location.where(name: district_name).first.id

    ta_name = params[:ta]
    location_id_for_ta = Location.where("name = ? AND parent_location = ?",
      ta_name, location_id_for_district).first.id


    nationality_tag = LocationTag.where(name: 'Village').first
    data = []
    Location.where("LENGTH(name) > 0 AND name LIKE (?) AND m.location_tag_id = ?
      AND parent_location = ?", "#{params[:search]}%", nationality_tag.id,
      location_id_for_ta).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << l.name
    end

    if data.present?
      render text: ("<li>" + data.compact.uniq.join("</li><li>") + "</li>") and return
    else
      render text: "" and return
    end
  end

  def get_hospital
  map =  {'Mzuzu City' => 'Mzimba',
          'Lilongwe City' => 'Lilongwe',
          'Zomba City' => 'Zomba',
          'Blantyre City' => 'Blantyre'}

  if  (params[:district].match(/City$/) rescue false)
    params[:district] =map[params[:district]]
  end

  nationality_tag = LocationTag.where("name = 'Hospital' OR name = 'Health Facility'").first
  data = []
  parent_location = Location.where(" name = '#{params[:district]}' AND COALESCE(code, '') != '' ").first.id rescue nil

  Location.where("LENGTH(name) > 0 AND name LIKE (?) AND parent_location = #{parent_location} AND m.location_tag_id = ?",
    "#{params[:search]}%", nationality_tag.id).joins("INNER JOIN location_tag_map m
    ON location.location_id = m.location_id").order('name ASC').map do |l|
    data << l.name
  end

  if data.present?
    render text: ("<li>" + data.compact.uniq.join("</li><li>") + "</li>") and return
  else
    render text: "" and return
  end
 end

  def view_sync
     render :layout => "facility"
  end

  def view_cases

    if SETTINGS['application_mode'] == "FC"
        @states = ["DC-ACTIVE","FC-POTENTIAL DUPLICATE"]
    else
       @states = ["DC-ACTIVE"]
    end
    @section = "New Cases"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)
    @targeturl = "/manage_cases"
    @records = [] #PersonService.query_for_display(@states)

    render :template => "person/records", :layout => "data_table"
  end

  def view_complete_cases
    @states = ["DC-COMPLETE"]
    @section = "Complete Cases"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)
    @targeturl = "/manage_cases"
    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def view_incomplete_cases
    @states = ["DC-INCOMPLETE"]
    @section = "Incomplete Cases"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)
    @targeturl = "/manage_cases"
    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def view_pending_cases
    @states = ["DC-PENDING","DC-INCOMPLETE"]
    @section = "Pending Cases"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)

    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def view_rejected_cases
    @states = ["DC-REJECTED"]
    @section = "Rejected Cases"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)

    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def view_hq_rejected_cases
    @states = ["HQ-REJECTED"]
    @section = "Rejected Cases at HQ"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)
    @display_ben = true
    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def edit

    if params[:next_path].blank?
      @targeturl = request.referrer
    else
      @targeturl = params[:next_path]
    end

    @section = "Edit Record"

    @person = Person.find(params[:id])
    @core_person = CorePerson.find(params[:id])

    #New Variables

    @birth_details = PersonBirthDetail.where(person_id: @core_person.person_id).last
    @name = @person.person_names.last
    @address = @person.addresses.last

    @mother_person = @person.mother
    @mother_address = @mother_person.addresses.last rescue nil
    @mother_name = @mother_person.person_names.last rescue nil

    @father_person = @person.father
    @father_address = @father_person.addresses.last rescue nil
    @father_name = @father_person.person_names.last rescue nil

    @informant_person = @person.informant rescue nil
    @informant_address = @informant_person.addresses.last rescue nil
    @informant_name = @informant_person.person_names.last rescue nil

    @comments = PersonRecordStatus.where(" person_id = #{@person.id} AND COALESCE(comments, '') != '' ")
    days_gone = ((@birth_details.acknowledgement_of_receipt_date.to_date rescue Date.today) - @person.birthdate.to_date).to_i rescue 0
    @delayed =  days_gone > 42 ? "Yes" : "No"
    location = Location.find(SETTINGS['location_id'])
    facility_code = location.code
    birth_loc = Location.find(@birth_details.birth_location_id)

    birth_location = birth_loc.name rescue nil

    @place_of_birth = birth_loc.name rescue nil

    if birth_location == 'Other' && @birth_details.other_birth_location.present?
      @birth_details.other_birth_location
    end

    @place_of_birth = @birth_details.other_birth_location if @place_of_birth.blank?

    @status = PersonRecordStatus.status(@person.id)

    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, [@status])
    informant_rel = (!@birth_details.informant_relationship_to_person.blank? ?
        @birth_details.informant_relationship_to_person : @birth_details.other_informant_relationship_to_person) rescue nil

    @record = {
        "Details of Child" => [
            {
                "Birth Entry Number" => "#{@birth_details.ben rescue nil}",
                "Birth Registration Number" => "#{@birth_details.brn  rescue nil}"
            },
            {
                ["First Name","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=child_first_name"] => "#{@name.first_name rescue nil}",
                ["Other Name","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=child_middle_name"] => "#{@name.middle_name rescue nil}",
                ["Surname", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=child_surname"] => "#{@name.last_name rescue nil}"
            },
            {
                ["Date of birth", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=child_birthdate"] => "#{@person.birthdate.to_date.strftime('%d/%b/%Y') rescue nil}",
                ["Sex", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=child_gender"] => "#{(@person.gender == 'F' ? 'Female' : 'Male')}",
                ["Place of birth","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_place_of_birth"] => "#{loc(@birth_details.place_of_birth, 'Place of Birth')}"
            },
            {
                ["Name of Hospital","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_hospital_of_birth"] => "#{loc(@birth_details.birth_location_id, 'Health Facility')}",
                ["Other Details","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_other_details"] => "#{@birth_details.other_birth_location}",
                ["Address","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=child_birth_address"] => "#{@child.birth_address rescue nil}"
            },
            {
                ["District", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_location_district"] => "#{birth_loc.district}",
                ["T/A", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_location_ta"] => "#{birth_loc.ta}",
                ["Village","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_location_village"] => "#{birth_loc.village rescue nil}"
            },
            {
                ["Birth weight (kg)","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_birth_weight"] => "#{@birth_details.birth_weight rescue nil}",
                ["Type of birth","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_birth_type"] => "#{@birth_details.birth_type.name rescue nil}",
                ["Other birth specified","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_other_birth_type"] => "#{@birth_details.other_type_of_birth rescue nil}"
            },
            {
                ["Are the parents married to each other?" ,"/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_parents_married_to_each_other"] => "#{(@birth_details.parents_married_to_each_other.to_s == '1' ? 'Yes' : 'No') rescue nil}",
                ["If yes, date of marriage","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_date_of_marriage"] => "#{@birth_details.date_of_marriage.to_date.strftime('%d/%b/%Y')  rescue nil}"
            },
            {
                ["Court Order Attached?","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_court_order_attached"] => "#{(@birth_details.court_order_attached.to_s == "1" ? 'Yes' : 'No') rescue nil}",
                ["Parents Signed?","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_parents_signed"] => "#{(@birth_details.parents_signed == "1" ? 'Yes' : 'No') rescue nil}",
                "Record Complete?" => (@birth_details.record_complete? rescue false) ? "Yes" : "No"
            },
            {
                "Place where birth was recorded" => "#{loc(@birth_details.location_created_at)}",
                "Record Status" => "#{@status}",
                "Child/Person Type" => "#{@birth_details.reg_type.name}"
            }
        ],
        "Details of Child's Mother" => [
            {
                ["First Name", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_first_name"] => "#{@mother_name.first_name rescue nil}",
                ["Other Name", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_middle_name"] => "#{@mother_name.middle_name rescue nil}",
                ["Maiden Surname", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_maiden_name"] => "#{@mother_name.last_name rescue nil}"
            },
            {
                ["Date of birth", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_birth_date"] => "#{@mother_person.birthdate.to_date.strftime('%d/%b/%Y') rescue nil}",
                ["Nationality", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_citizenship"] => "#{@mother_person.citizenship rescue nil}",
                ["ID Number", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_id_number"] => "#{@mother_person.id_number rescue nil}"
            },
            {
                ["Physical Residential Address, District", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_address_current_district"] => "#{loc(@mother_address.current_district, 'District') rescue nil}",
                ["T/A", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_address_current_ta"] => "#{loc(@mother_address.current_ta, 'Traditional Authority') rescue nil}",
                ["Village/Town", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_address_current_village"] => "#{loc(@mother_address.current_village, 'Village') rescue nil}"
            },
            {
                ["District", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_address_home_district"] => "#{loc(@mother_address.home_district, 'District') rescue nil}",
                ["T/A", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_address_home_ta"] => "#{loc(@mother_address.home_ta, 'Traditional Authority') rescue nil}",
                ["Home Address, Village/Town", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=mother_address_home_village"] => "#{loc(@mother_address.home_village, 'Village') rescue nil}"
            },
            {
                ["Gestation age at birth in weeks", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_gestation_at_birth"] => "#{@birth_details.gestation_at_birth rescue nil}",
                ["Number of prenatal visits", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_number_of_prenatal_visits"] => "#{@birth_details.number_of_prenatal_visits rescue nil}",
                ["Month of pregnancy prenatal care started", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_month_prenatal_care_started"] => "#{@birth_details.month_prenatal_care_started rescue nil}"
            },
            {
                ["Mode of delivery", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_mode_of_delivery"] => "#{@birth_details.mode_of_delivery.name rescue nil}",
                ["Number of children born to the mother, including this child", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_number_of_children_born_alive_inclusive"] => "#{@birth_details.number_of_children_born_alive_inclusive rescue nil}",
                ["Number of children born to the mother, and still living","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_number_of_children_born_still_alive"] => "#{@birth_details.number_of_children_born_still_alive rescue nil}"
            },
            {
                ["Level of education", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_level_of_education"] => "#{@birth_details.level_of_education rescue nil}"
            }
        ],
        "Details of Child's Father" => [
            {
                ["First Name", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_first_name"] => "#{@father_name.first_name rescue nil}",
                ["Other Name", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_middle_name"] => "#{@father_name.middle_name rescue nil}",
                ["Surname", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=person_surname" ] => "#{@father_name.last_name rescue nil}"
            },
            {
                ["Date of birth", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_birthdate"] => "#{@father_person.birthdate.to_date.strftime('%d/%b/%Y') rescue nil}",
                ["Nationality", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_citizenship"] => "#{@father_person.citizenship rescue nil}",
                ["ID Number", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_id_number"] => "#{@father_person.id_number rescue nil}"
            },
            {
                ["Physical Residential Address, District", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_address_current_district"] => "#{loc(@father_address.current_district, 'District') rescue nil}",
                ["T/A", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_address_current_ta"] => "#{loc(@father_address.current_ta, 'Traditional Authority') rescue nil}",
                ["Village/Town", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_address_current_village"] => "#{loc(@father_address.current_village, 'Village') rescue nil}"
            },
            {
                ["District", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_address_home_district"] => "#{loc(@father_address.home_district, 'District') rescue nil}",
                ["T/A", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_address_home_ta"] => "#{loc(@father_address.home_ta, 'Traditional Authority') rescue nil}",
                ["Home Address, Village/Town", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=father_address_home_village"] => "#{loc(@father_address.home_village, 'Village') rescue nil}"
            }
        ],
        "Details of Child's Informant" => [
            {
                ["First Name", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_first_name"] => "#{@informant_name.first_name rescue nil}",
                ["Other Name", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_middle_name"] => "#{@informant_name.middle_name rescue nil}",
                ["Family Name", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_family_name"] => "#{@informant_name.last_name rescue nil}"
            },
            {
                ["Relationship to child", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_relationship"] => informant_rel,
                ["ID Number","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_id_number"] => "#{@informant_person.id_number rescue ""}"
            },
            {
                ["Physical Address, District", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_address_home_district"] => "#{loc(@informant_address.home_district, 'District')rescue nil}",
                ["T/A","/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_address_current_ta"] => "#{loc(@informant_address.current_ta, 'Traditional Authority') rescue nil}",
                ["Village/Town", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_address_current_village"] => "#{loc(@informant_address.current_village, 'Village') rescue nil}"
            },
            {
                ["Postal Address", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_address"] => "#{@informant_address.address_line_1 rescue nil}",
                "" => "#{@informant_address.address_line_2 rescue nil}",
                ["City", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_address_city"]  => "#{@informant_address.city rescue nil}"
            },
            {
                ["Phone Number", "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=informant_cell_phone_number"]  => "#{@informant_person.get_attribute('Cell Phone Number') rescue nil}",
                ["Informant Signed?" , "/update_person?id=#{@person.person_id}&next_path=#{@targeturl}&field=birth_details_form_signed"]  => "#{(@birth_details.form_signed == 1 ? 'Yes' : 'No')}"
            },
            {
                "Acknowledgement Date" => "#{@birth_details.acknowledgement_of_receipt_date.to_date.strftime('%d/%b/%Y') rescue ""}",
                "Date of Registration" => "#{@birth_details.date_registered.to_date.strftime('%d/%b/%Y') rescue ""}",
                "Delayed Registration" => "#{@delayed}"
            }
        ]
    }



    @summaryHash = {

      "Child Name" => @person.name,
      "Child Gender" => ({'M' => 'Male', 'F' => 'Female'}[@person.gender.strip.split('')[0]] rescue @person.gender),
      "Child Date of Birth" => @person.birthdate.to_date.strftime("%d/%b/%Y"),
      "Place of Birth" => "#{Location.find(@birth_details.birth_location_id).name rescue nil}",
      "Child's Mother " => (@mother_person.name rescue nil),
      "Child's Father" =>  (@father_person.name rescue nil),
      "Parents Married" => (@birth_details.parents_married_to_each_other.to_s == '1' ? 'Yes' : 'No'),
      "Court order attached" => (@birth_details.court_order_attached.to_s == '1' ? 'Yes' : 'No'),
      "Parents signed?" => ((@birth_details.parents_signed rescue -1).to_s == '1' ? 'Yes' : 'No'),
      "Delayed Registration" => @delayed
    }

    if  (BirthRegistrationType.find(@person_details.birth_registration_type_id).name.upcase rescue nil) == 'ADOPTED'
      @summaryHash["Adoptive Mother"] = nil
      @summaryHash[ "Adoptive Father"] = nil
      @summaryHash["Adoption Court Order"] = nil
    end

    render :layout => "facility"

  end

  def view_printed_cases
    @states = ["HQ-PRINTED"]
    @section = "Printed Cases"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)
    @display_ben = true
    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def view_voided_cases
    @states = ["DC-VOIDED"]
    @section = "Voided Cases"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)

    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def view_approved_cases
    @states = Status.where("name like 'HQ-%' ").map(&:name) - ['HQ-REJECTED', 'HQ-VOIDED', 'HQ-PRINTED', 'HQ-DISPATCHED']
    @section = "Approved Cases"
    @display_ben = true
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)

   # @records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def view_dispatched_cases
    @states = ["HQ-DISPATCHED"]
    @section = "Voided Cases"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)

    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def lost_and_damaged_cases
    @states = ["DC-LOST", 'DC-DAMAGED']
    @section = "Lost/Damaged Cases"
    @display_ben = true
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)

    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end


  def ammendment_cases
    @states = ['DC-AMEND']
    @section = "Ammendments"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)
    @display_ben = true
    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def rejected_ammendment_cases
    @states = ['DC-AMEND-REJECTED','DC-LOST-REJECTED','DC-DAMAGED-REJECTED']
    @section = "Rejected Amendments"
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)
    @display_ben = true
    #@records = PersonService.query_for_display(@states)
    render :template => "person/records", :layout => "data_table"
  end

  def ammend_case
    @person = Person.find(params[:id])
    @status = PersonRecordStatus.status(@person.id)
    if @status != "DC-AMEND"
       #PersonRecordStatus.new_record_state(params['id'], "DC-AMEND", "Amendment request; #{params['reason']}")
    end

    @prev_details = {}
    @birth_details = PersonBirthDetail.where(person_id: params[:id]).last

    @name = @person.person_names.last

    @person_prev_values = {}
    name_fields = ['first_name','last_name','middle_name',"gender","birthdate","birth_location_id"]
    name_fields.each do |field|
        trail = AuditTrail.where(person_id: params[:id], field: field).order('created_at').last
        if trail.present?
            @person_prev_values[field] = trail.previous_value
        end
    end

    if @person_prev_values['first_name'].present? || @person_prev_values['last_name'].present?
        name = "#{@person_prev_values['first_name'].present? ? @person_prev_values['first_name'] : @name.first_name} "+
               "#{@person_prev_values['middle_name'].present? ? @person_prev_values['middle_name'] : (@name.middle_name rescue '')} " +
               "#{@person_prev_values['last_name'].present? ? @person_prev_values['last_name'] : @name.last_name}"
        @person_prev_values["person_name"] = name
    end



    @address = @person.addresses.last

    @mother_person = @person.mother
    @mother_name = @mother_person.person_names.last rescue nil
    @mother_prev_values = {}
    name_fields.each do |field|
        trail = AuditTrail.where(person_id: @mother_person.id, field: field).order('created_at').last
        if trail.present?
            @mother_prev_values[field] = trail.previous_value
        end
    end

    if @mother_prev_values['first_name'].present? || @mother_prev_values['last_name'].present?
        mother_name = "#{@mother_prev_values['first_name'].present? ? @mother_prev_values['first_name'] : @mother_name.first_name} "+
               "#{@mother_prev_values['middle_name'].present? ? @mother_prev_values['middle_name'] : (@mother_name.middle_name rescue '')} " +
               "#{@mother_prev_values['last_name'].present? ? @mother_prev_values['last_name'] : @mother_name.last_name}"
        @person_prev_values["mother_name"] = mother_name
    end

    @father_person = @person.father
    @father_name = @father_person.person_names.last rescue nil

    @father_prev_values = {}
    name_fields.each do |field|
        break if @father_person.blank?
        trail = AuditTrail.where(person_id: @father_person.id, field: field).order('created_at').last

        if trail.present?
            @father_prev_values[field] = trail.previous_value
        end
    end

    if @father_prev_values['first_name'].present? || @father_prev_values['last_name'].present?
        father_name = "#{@father_prev_values['first_name'].present? ? @father_prev_values['first_name'] : @father_name.first_name} "+
               "#{@father_prev_values['middle_name'].present? ? @father_prev_values['middle_name'] : (@father_name.middle_name rescue '')} " +
               "#{@father_prev_values['last_name'].present? ? @father_prev_values['last_name'] : @father_name.last_name}"
        @person_prev_values["father_name"] = father_name
    end
    @targeturl = params[:next_path]
    @section = 'Ammend Case'
    render :layout => "facility"
  end

  def amend_edit
    @person = Person.find(params[:id])
    @birth_details = PersonBirthDetail.where(person_id: params[:id]).last
    @name = @person.person_names.last
    @address = @person.addresses.last

    @mother_person = @person.mother
    @mother_name = @mother_person.person_names.last rescue nil

    @father_person = @person.father
    @father_name = @father_person.person_names.last rescue nil
     @targeturl = "/person/ammend_case?id=#{params[:id]}"
    render :layout => "touch"
  end

  def amend_field
    fields = params[:fields].split(",")

    if fields.include? "Name"
      person_name = PersonName.find_by_person_id(params[:id])
      person_name.update_attributes(voided: true, void_reason: 'Amendment edited')
      person_name = PersonName.create(person_id: params[:id],
            first_name: params[:person][:first_name],
            last_name: params[:person][:last_name],middle_name: params[:person][:middle_name])
    end
    if fields.include? "Date of birth"
        person = Person.find(params[:id])
        person.update_attributes(birthdate: params[:person][:birthdate], birthdate_estimated: (params[:person][:birthdate_estimated]? params[:person][:birthdate_estimated] : 0))
    end
    if fields.include? "Sex"
       person = Person.find(params[:id])
       gender = params[:person][:gender]  == "Female" ? 'F' : 'M'
       person.update_attributes(gender: gender)
    end
    if fields.include? "Place of birth"
        person_birth_details = PersonBirthDetail.where(person_id: params[:id]).last
        place_of_birth = params[:person][:place_of_birth]
        place_of_birth_id = Location.locate_id_by_tag(params[:person][:place_of_birth], 'Place of Birth')

        case place_of_birth
        when "Home"
          district_id = Location.locate_id_by_tag(params[:person][:birth_district], 'District')
          ta_id = Location.locate_id(params[:person][:birth_ta], 'Traditional Authority', district_id)
          village_id = Location.locate_id(params[:person][:birth_village], 'Village', ta_id)
          location_id = [village_id, ta_id, district_id].compact.first

          person_birth_details.place_of_birth = place_of_birth_id
          person_birth_details.district_of_birth = district_id
          person_birth_details.birth_location_id = location_id
          person_birth_details.other_birth_location = nil
          person_birth_details.save
        when "Hospital"
           map =  {'Mzuzu City' => 'Mzimba',
                'Lilongwe City' => 'Lilongwe',
                'Zomba City' => 'Zomba',
                'Blantyre City' => 'Blantyre'}

          params[:person][:birth_district] = map[params[:person][:birth_district]] if params[:person][:birth_district].match(/City$/)

          district_id = Location.locate_id_by_tag(params[:person][:birth_district], 'District')
          location_id = Location.locate_id(params[:person][:hospital_of_birth], 'Health Facility', district_id)

          location_id = [location_id, district_id].compact.first

          person_birth_details.place_of_birth = place_of_birth_id
          person_birth_details.district_of_birth = district_id
          person_birth_details.birth_location_id = location_id
          person_birth_details.other_birth_location = nil
          person_birth_details.save
        when "Other"
          district_id = Location.locate_id_by_tag(params[:person][:birth_district], 'District')
          location_id = Location.where(name: 'Other').last.id #Location.locate_id_by_tag(person[:birth_district], 'District')
          other_place_of_birth = params[:other_birth_place_details]

          person_birth_details.place_of_birth = place_of_birth_id
          person_birth_details.district_of_birth = district_id
          person_birth_details.birth_location_id = location_id
          person_birth_details.other_birth_location = other_place_of_birth
          person_birth_details.save
        end
    end
    if fields.include? "Name of mother"
        person = Person.find(params[:id])
        person_mother_name = person.mother.person_names.last
        person_mother_name.update_attributes(voided: true, void_reason: 'Amendment edited')
        person_mother_name = PersonName.create(person_id: person.mother.id,
            first_name: params[:person][:mother][:first_name],
            last_name: params[:person][:mother][:last_name],
            middle_name: params[:person][:mother][:middle_name])

        PersonNameCode.create(person_name_id: person_mother_name.person_name_id,
            first_name_code: params[:person][:mother][:first_name].soundex,
            last_name_code: params[:person][:mother][:last_name].soundex,
            middle_name_code: params[:person][:mother][:middle_name].soundex)
    end
    if fields.include? "Name of father"
        person = Person.find(params[:id])
        @father_person = person.father

        if @father_person.present?
          person_father_name = person.father.person_names.last
            if person_father_name.present?
              person_father_name.update_attributes(voided: true, void_reason: 'Amendment edited')
            end
        else
            core_person = CorePerson.create(
                :person_type_id     => PersonType.where(name: 'Father').last.id,
            )

            @father_person = Person.create(
                :person_id          => core_person.id,
                :gender             => 'M',
                :birthdate          => (params[:person][:father][:birthdate].blank? ? "1900-01-01" : params[:person][:father][:birthdate].to_date),
                :birthdate_estimated => (params[:person][:father][:birthdate].blank? ? 1 : 0)
            )
        end


        person_father_name = PersonName.create(person_id: @father_person.id,
              first_name: params[:person][:father][:first_name],
              last_name: params[:person][:father][:last_name],
              middle_name: params[:person][:father][:middle_name])

        PersonNameCode.create(person_name_id: person_father_name.person_name_id,
              first_name_code: params[:person][:father][:first_name].soundex,
              last_name_code: params[:person][:father][:last_name].soundex,
              middle_name_code: params[:person][:father][:middle_name].soundex)

        PersonRelationship.create(
                person_a: person.id, person_b: @father_person.person_id,
                person_relationship_type_id: PersonRelationType.where(name: 'Father').last.id
        )
    end
    redirect_to "/person/ammend_case?id=#{params[:id]}&next_path=#{params[:next_path]}"
  end

  def amendiment_comment
      render :layout => "touch"
  end
  def reprint_case
    @section = "Re-pring case"
    render :layout =>"touch"
  end

  def do_amend
    PersonRecordStatus.new_record_state(params['id'], "DC-AMEND", "Amendment request; #{params['reason']}")

    redirect_to (params[:next_path]? params[:next_path] : "/manage_requests")
  end

  def do_reprint
    PersonRecordStatus.new_record_state(params['id'], "DC-#{params['reason'].upcase}", "Reprint request; #{params['reason']}");

    redirect_to session['list_url']
  end

  def approve_reprint_request
    PersonRecordStatus.new_record_state(params['id'], "HQ-#{params['reason'].upcase}", "Reprint request; #{params['reason']}");

    redirect_to session['list_url']
  end

  def approve_amendment_request
    PersonRecordStatus.new_record_state(params['id'], "HQ-AMEND", "Amendment request; Verifed by ADR");

    redirect_to session['list_url']
  end

  def searched_cases
    @states = Status.all.map(&:name)
    @section = "Search Cases"
    @display_ben = true
    @search = true
    @user = User.find(params[:user_id])
    User.current = @user
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)
    filters = JSON.parse(params['data']) rescue {}
    @records = PersonService.search_results(filters)

    render :template => "person/records", :layout => "data_table"
  end
  #########################################################################

  def paginated_data
    params[:statuses] = [] if params[:statuses].blank?
    states = params[:statuses].split(',')
    types = []

    search_val = params[:search][:value] rescue nil
    search_val = '_' if search_val.blank?
    if !params[:start].blank?

      state_ids = states.collect{|s| Status.find_by_name(s).id} + [-1]

      if params[:type] == 'All'
        types=['Normal', 'Abandoned', 'Adopted', 'Orphaned']
      else
        types=[params[:type]]
      end

      person_reg_type_ids = BirthRegistrationType.where(" name IN ('#{types.join("', '")}')").map(&:birth_registration_type_id) + [-1]

      d = Person.order(" pbd.district_id_number, pbd.national_serial_number, n.first_name, n.last_name, cp.created_at ")
      .joins(" INNER JOIN core_person cp ON person.person_id = cp.person_id
              INNER JOIN person_name n ON person.person_id = n.person_id
              INNER JOIN person_record_statuses prs ON person.person_id = prs.person_id AND COALESCE(prs.voided, 0) = 0
              INNER JOIN person_birth_details pbd ON person.person_id = pbd.person_id ")
      .where(" prs.status_id IN (#{state_ids.join(', ')})
              AND pbd.birth_registration_type_id IN (#{person_reg_type_ids.join(', ')}) AND n.voided = 0
              AND concat_ws('_', pbd.national_serial_number, pbd.district_id_number, n.first_name, n.last_name, n.middle_name,
                person.birthdate, person.gender) REGEXP '#{search_val}' ")

      total = d.select(" count(*) c ")[0]['c'] rescue 0
      page = (params[:start].to_i / params[:length].to_i) + 1

      data = d.group(" prs.person_id ")

      data = data.select(" n.*, prs.status_id, pbd.district_id_number AS ben, person.gender, person.birthdate, pbd.national_serial_number AS brn, pbd.date_reported ")
      data = data.page(page)
      .per_page(params[:length].to_i)

      @records = []
      data.each do |p|
        mother = PersonService.mother(p.person_id)
        father = PersonService.father(p.person_id)
        details = PersonBirthDetail.find_by_person_id(p.person_id)

        name          = ("#{p['first_name']} #{p['middle_name']} #{p['last_name']}")
        mother_name   = ("#{mother.first_name rescue 'N/A'} #{mother.middle_name rescue ''} #{mother.last_name rescue ''}")
        father_name   = ("#{father.first_name rescue 'N/A'} #{father.middle_name rescue ''} #{father.last_name rescue ''}")
        row = []
        row = [p.ben] if params[:assign_ben] == 'true'
        row = row + [
            "#{name} (#{p.gender})",
            p.birthdate.strftime('%d/%b/%Y'),
            mother_name,
            father_name,
            (p.date_reported.strftime('%d/%b/%Y') rescue nil),
            Status.find(p.status_id).name,
            p.person_id
        ]
        @records << row
      end

      render :text => {
          "draw" => params[:draw].to_i,
          "recordsTotal" => total,
          "recordsFiltered" => total,
          "data" => @records}.to_json and return
    end

  end

  def paginated_search_data
    filters = JSON.parse(params['data']) rescue {}
    @records = PersonService.search_results(filters, params)

    render text: @records.to_json
  end

  def search_by_nid
    data = []
    nid_type_id = PersonIdentifierType.where(name: "National ID Number").last.id

    nids = PersonIdentifier.where(person_identifier_type_id: nid_type_id, voided: 0, value: params[:nid])

    nids.each do |id|
      person = Person.find(id.person_id)

      next if (person.gender.to_s != params[:gender].to_s)
      name = PersonName.where(person_id: id.person_id).last
      next if name.blank?

      address = PersonAddress.where(person_id: id.person_id).last

      data << {
          'first_name'    => (name.first_name rescue ''),
          'last_name'     => (name.last_name rescue ''),
          'gender'        => (({'F' => 'Female', 'M' => 'Male'}[person.gender]) rescue nil),
          'birthdate'     =>  (person.birthdate.strftime("%d-%b-%Y") rescue nil),
          'home_district' => (Location.find(address.home_district).name rescue nil),
          'home_ta'       => (Location.find(address.home_ta).name rescue nil),
          'home_village'  => (Location.find(address.home_village).name rescue nil),
          'person_id'     => id.person_id
      }
    end

    render text: data.to_json
  end

  def check_sync
    sync = Syncs.where(person_id: params['person_id'])

    if !sync.blank?
      render :text => {'person_id' => params['person_id'],
                       'result' => 'true'}.to_json and return
    end

    url = SETTINGS['destination_app_link'] + "/sync_status?person_id=#{params['person_id']}"
    result = RestClient.get(url) rescue 'false'

    if result.to_s == 'true'
      sync = Syncs.where(person_id: params['person_id'])
      if sync.blank?
        Syncs.create(
            level: SETTINGS['application_mode'],
            person_id: params['person_id']
        )
      end
    end

    render :text => {'person_id' => params['person_id'],
                     'result' => result}.to_json
  end

  def barcode_scan

    barcode = params[:value]
    render :layout => {}.to_json and return if barcode.blank?

    result = []
    if SETTINGS['scan_from_dde'].to_s == "true"

      link  = ""
    elsif SETTINGS['scan_from_remote'].to_s == "true"

      link = "#{SETTINGS['remote_url']}/people/demographics_remote"
      hash = { "person" => {"patient" => {"identifiers" => {"National id" => barcode}}}}

      data  = JSON.parse(RestClient.post(link, hash.to_json, :content_type => "application/json")) rescue []

      data  = [data] if data.class != Array && !data.blank?

      (data || []).each do |d|
        d = d['person']
        result << [{
                       "first_name"           => d['names']['given_name'],
                       "last_name"            => d['names']['family_name'],
                       "middle_name"          => d['names']['family_name2'],
                       "gender"               => d['gender'],
                       "birth_date"           => "#{d['birth_day']}/#{d['birth_month']}/#{d['birth_year']}".to_date.to_s,
                       "home_district"        => d['addresses']['address2'],
                       "home_ta"              => d['addresses']['county_district'],
                       "home_village"         => d['addresses']['neighborhood_cell'],
                       "current_district"     => d['addresses']['state_province'],
                       "current_ta"           => d['addresses'][''],
                       "current_village"      => d['addresses']['city_village'],
                       "citizenship"          => "Malawi",
                       "country_of_residence" => "Malawi",
                       "cell_phone_number"    => (!d['attributes']['cell_phone_number'].blank? &&
                                                      d['attributes']['cell_phone_number'].match(/\d+/) ?
                                                      d['attributes']['cell_phone_number'] : nil  )
                   }]
      end
    end

    render :text => result.to_json
  end

end
