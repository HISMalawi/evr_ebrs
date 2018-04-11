sample = {
	'birth_date' : "1983-05-05",
	'cell_phone_number' : null,
	'citizenship' : "Malawi",
	'country_of_residence' : "Malawi",
	'current_district' : "Thyolo",
	'current_ta' : null,
	'current_village' : "Conforzi Estate Chipiloni Lines",
	'first_name' : "Mary",
	'gender' : "F",
	'home_district' : "Thyolo",
	'home_ta' : "Nchilamwela",
	'home_village' : "Conforzi Estate Chipiloni Lines",
	'last_name' : "Nampinga",
	'middle_name' : null
};

iTable = {
	init: function(hash, parent) {
		var table = document.createElement("table");
		table.style.border = '2px black solid';
		table.style.width = '95%';

		var caption = document.createElement("caption");
		var number_of_records = hash.length;
		caption.innerHTML = (number_of_records===1?number_of_records+' record found':number_of_records + ' records found');
		table.appendChild(caption);

		for(var key in hash){

			// Create Main Row for Record
			var person_row = document.createElement("tr");
			table.appendChild(person_row);

			// Create Column 1 to hold Table Headers
			var person_header_td = document.createElement("td");
			person_row.appendChild(person_header_td);

			// -- row 1
			var person_header_first_name_row = document.createElement("tr");
			person_header_td.appendChild(person_header_first_name_row);

			var person_header_first_name = document.createElement("td");
			person_header_first_name.innerHTML = 'First Name';
			person_header_first_name_row.appendChild(person_header_first_name);

			// -- row 2
			var person_header_last_name_row = document.createElement("tr");
			person_header_td.appendChild(person_header_last_name_row);

			var person_header_last_name = document.createElement("td");
			person_header_last_name.innerHTML = 'Last Name';
			person_header_last_name_row.appendChild(person_header_last_name);

			// -- row 3
			var person_header_gender_row = document.createElement("tr");
			person_header_td.appendChild(person_header_gender_row);

			var person_header_gender = document.createElement("td");
			person_header_gender.innerHTML = 'Gender';
			person_header_gender_row.appendChild(person_header_gender);

			// -- row 4
			var person_header_birthdate_row = document.createElement("tr");
			person_header_td.appendChild(person_header_birthdate_row);

			var person_header_birthdate = document.createElement("td");
			person_header_birthdate.innerHTML = 'Birthdate';
			person_header_birthdate_row.appendChild(person_header_birthdate);

			// -- row 5
			var person_header_home_address_row = document.createElement("tr");
			person_header_td.appendChild(person_header_home_address_row);

			var person_header_home_address = document.createElement("td");
			person_header_home_address.innerHTML = 'Home Address';
			person_header_home_address_row.appendChild(person_header_home_address);

			// -- row 6
			var person_header_current_address_row = document.createElement("tr");
			person_header_td.appendChild(person_header_current_address_row);

			var person_header_current_address = document.createElement("td");
			person_header_current_address.innerHTML = 'Current Address';
			person_header_current_address_row.appendChild(person_header_current_address);

			// ----------- end of column 1 (person headers)

			// Create column 2 to hold Table Description
			var person_details_td = document.createElement("td");
			person_row.appendChild(person_details_td);

			// -- row 1
			var person_details_first_name_row = document.createElement("td");
			person_details_td.appendChild(person_details_first_name_row);

			var person_details_first_name = document.createElement("td");
			person_details_first_name.innerHTML = hash[0]['first_name'];
			person_details_first_name_row.appendChild(person_details_first_name);

			// -- row 2
			var person_details_last_name_row = document.createElement("td");
			person_details_td.appendChild(person_details_last_name_row);

			var person_details_last_name = document.createElement("td");
			person_details_last_name.innerHTML = hash[0]['last_name'];
			person_details_last_name_row.appendChild(person_details_last_name);

			// -- row 3
			var person_details_gender_row = document.createElement("td");
			person_details_td.appendChild(person_details_gender_row);

			var person_details_gender = document.createElement("td");
			person_details_gender.innerHTML = (hash[0]['gender']==='F')?'Female':'Male';
			person_details_gender_row.appendChild(person_details_gender);

			// -- row 4
			var person_details_birthdate_row = document.createElement("td");
			person_details_td.appendChild(person_details_birthdate_row);

			var person_details_birthdate = document.createElement("td");
			person_details_birthdate.innerHTML = hash[0]['birth_date'];
			person_details_birthdate_row.appendChild(person_details_birthdate);

			// -- row 5
			var person_details_home_address_row = document.createElement("td");
			person_details_td.appendChild(person_details_home_address_row);

			var person_details_home_address = document.createElement("td");
			person_details_home_address.innerHTML = hash[0]['home_village'] + ',' + hash[0]['home_ta'] + ',' + hash[0]['home_district'];
			person_details_home_address_row.appendChild(person_details_home_address);

			// -- row 6
			var person_details_current_address_row = document.createElement("td");
			person_details_td.appendChild(person_details_current_address_row);

			var person_details_current_address = document.createElement("td");
			person_details_current_address.innerHTML = hash[0]['current_village'] + ',' + hash[0]['current_ta'] + ',' + hash[0]['current_district'];
			person_details_current_address_row.appendChild(person_details_current_address);

			// ----------- end of column 2 (person details)

			// Create column 3 to hold Action Buttons
			var person_action_td = document.createElement("td");
			person_row.appendChild(person_action_td);

			var person_action_td_row = document.createElement("tr");
			person_action_td.appendChild(person_action_td_row);

			var person_action_td_row_td = document.createElement("td");
			person_action_td_row.appendChild(person_action_td_row_td);

			var person_action_select_button = document.createElement("button");
			var person_action_select_button_text = document.createTextNode("Select");
			person_action_select_button.appendChild(person_action_select_button_text);
			person_action_select_button.onmousedown = function() {
				var person_type = (hash[0]['gender']==='F')?'Mother':'Father';
				getDataAndStore(hash[0], person_type, 'select_only');
			};
			person_action_td_row_td.appendChild(person_action_select_button);

			var person_action_select_and_edit_button = document.createElement("button");
			var person_action_select_and_edit_button_text = document.createTextNode("Select & Edit");
			person_action_select_and_edit_button.appendChild(person_action_select_and_edit_button_text);
			person_action_select_and_edit_button.onmousedown = function() {
				var person_type = (hash[0]['gender']==='F')?'Mother':'Father';
				getDataAndStore(hash[0], person_type, 'select_and_edit');
			};
			person_action_td_row_td.appendChild(person_action_select_and_edit_button);

			// ----------- end of column 3 (action buttons)
		}
		parent.append(table);
		return table;
	}
};

function getDataAndStore(person_params, person_type, action) {

	var person_details = person_params;

	var person_type_value = person_type.toLowerCase();
	__$(person_type_value+'_first_name').value = person_details.first_name;
	__$(person_type_value+'_last_name').value = person_details.last_name;
	__$(person_type_value+'_birthdate').value = person_details.birth_date;
	__$('person_'+person_type_value+'_citizenship').value = (person_details.citizenship === 'Malawi')?'Malawian':person_details.citizenship;
	__$('person_'+person_type_value+'_local_residential_country').value = person_details.country_of_residence;
	__$('person_'+person_type_value+'_home_district').value = person_details.home_district;
	__$('person_'+person_type_value+'_home_ta').value = person_details.home_ta;
	__$('person_'+person_type_value+'_home_village').value = person_details.home_village.trim();
	__$('person_'+person_type_value+'_current_district').value = person_details.current_district;
	__$('person_'+person_type_value+'_current_ta').value = person_details.current_ta;
	__$('person_'+person_type_value+'_current_village').value = person_details.current_village;

	if(action === 'select_only') {
		autoNavigateAndSkip(person_type);
	} else {
		gotoPage(tstCurrentPage + 1);
	}

}

function autoNavigateAndSkip(person_type) {
	setTimeout(function () {
		if(person_type === 'Mother') {
			gotoPage(tstCurrentPage + 13);
		} else if(person_type === 'Father') {
			gotoPage(tstCurrentPage + 10);
		} else if(person_type === 'Informant') {
			gotoPage(tstCurrentPage + 14);
		}
	}, 200);
}

function loadParentDetails(parent_type) {

	var person_type = parent_type.toLowerCase();

	var parent_details = {};
	parent_details.first_name = __$(person_type+'_first_name').value.trim();
	parent_details.last_name = __$(person_type+'_last_name').value.trim();
	parent_details.birthdate = __$(person_type+'_birthdate').value.trim();
	parent_details.citizenship = __$('person_'+person_type+'_citizenship').value.trim();
	parent_details.local_residential_country = __$('person_'+person_type+'_local_residential_country').value.trim();
	parent_details.home_district = __$('person_'+person_type+'_home_district').value.trim();
	parent_details.home_ta = __$('person_'+person_type+'_home_ta').value.trim();
	parent_details.home_village = __$('person_'+person_type+'_home_village').value.trim();
	parent_details.current_district = __$('person_'+person_type+'_current_district').value.trim();
	parent_details.current_ta = __$('person_'+person_type+'_current_ta').value.trim();
	parent_details.current_village = __$('person_'+person_type+'_current_village').value.trim();

	return parent_details;
}

function loadInformantDetails(informant_type) {

	var preloaded_person = loadParentDetails(informant_type);

	__$('informant_first_name').value = preloaded_person.first_name;
	__$('informant_last_name').value = preloaded_person.last_name;
	__$('informant_birthdate').value = preloaded_person.birthdate;
	__$('person_informant_citizenship').value = preloaded_person.citizenship;
	__$('person_informant_local_residential_country').value = preloaded_person.local_residential_country;
	__$('person_informant_relationship_to_person').value = informant_type;
	__$('other_informant_relationship_to_person').value = '';
	__$('person_informant_home_district').value = preloaded_person.home_district;
	__$('person_informant_home_ta').value = preloaded_person.home_ta;
	__$('person_informant_home_village').value = preloaded_person.home_village;
	__$('person_informant_current_district').value = preloaded_person.current_district;
	__$('person_informant_current_ta').value = preloaded_person.current_ta;
	__$('person_informant_current_village').value = preloaded_person.current_village;
	__$('person_informant_phone_number').value = 'Unknown';

	autoNavigateAndSkip('Informant');
}