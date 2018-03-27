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
}

iTable = {
	init: function(hash, parent){
		var table = document.createElement("table");
		
		for(var k in hash){
			var tr  = document.createElement("tr");
			var td1 = document.createElement("td"); 
			var td2 = document.createElement("td"); 

			td1.innerHTML  = k; td2.innerHTML  = hash[k];
			tr.appendChild(td1); tr.appendChild(td2);

			table.appendChild(tr);		
		}
		parent.append(table);
		return table;
	}
}
