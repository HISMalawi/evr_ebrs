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
	init: function(hash, parent){
		var table = document.createElement("table");
		table.style.border = '2px black solid';
		table.style.width = '95%';

		var caption = document.createElement("caption");
		var number_of_records = hash.length;
		caption.innerHTML = (number_of_records===1?number_of_records+' record found':number_of_records + ' records found');
		table.appendChild(caption);

		var thr = document.createElement("tr");

		var thd1 = document.createElement("th");
		thd1.innerHTML = 'Index';
		thr.appendChild(thd1);

		var thd2 = document.createElement("th");
		thd2.innerHTML = 'First Name';
		thr.appendChild(thd2);

		var thd3 = document.createElement("th");
		thd3.innerHTML = 'Last Name';
		thr.appendChild(thd3);

		var thd4 = document.createElement("th");
		thd4.innerHTML = 'Gender';
		thr.appendChild(thd4);

		var thd5 = document.createElement("th");
		thd5.innerHTML = 'Birthdate';
		thr.appendChild(thd5);

		var thd6 = document.createElement("th");
		thd6.innerHTML = 'Home District';
		thr.appendChild(thd6);

		var thd7 = document.createElement("th");
		thd7.innerHTML = 'Home TA';
		thr.appendChild(thd7);

		var thd8 = document.createElement("th");
		thd8.innerHTML = 'Home Village';
		thr.appendChild(thd8);

		table.appendChild(thr);

		for(var key in hash){
			var tr  = document.createElement("tr");
			tr.style.left = '5px';
			tr.id = hash[0]['first_name'] + '_' + hash[0]['last_name'] + '_' + key;
			tr.onclick = function() {
				getDataAndStore(hash);
			};

			var td1 = document.createElement("td");
			td1.innerHTML  = parseInt(key) + 1;
			tr.appendChild(td1);

			var td2 = document.createElement("td");
			td2.innerHTML  = hash[0]['first_name'];
			tr.appendChild(td2);

			var td3 = document.createElement("td");
			td3.innerHTML  = hash[0]['last_name'];
			tr.appendChild(td3);

			var td4 = document.createElement("td");
			if("hash[0]['gender'] == 'F'") {
				var gender = 'Female';
			}else if("hash[0]['gender'] == 'F'") {
				var gender = 'Male';
			}
			td4.innerHTML  = gender;
			tr.appendChild(td4);

			var td5 = document.createElement("td");
			td5.innerHTML  = hash[0]['birth_date'];
			tr.appendChild(td5);

			var td6 = document.createElement("td");
			td6.innerHTML  = hash[0]['home_district'];
			tr.appendChild(td6);

			var td7 = document.createElement("td");
			td7.innerHTML  = hash[0]['home_ta'];
			tr.appendChild(td7);

			var td8 = document.createElement("td");
			td8.innerHTML  = hash[0]['home_village'];
			tr.appendChild(td8);

			table.appendChild(tr);
		}
		parent.append(table);
		return table;
	}
};

function getDataAndStore(hash_params) {
	alert('hello ');
}
