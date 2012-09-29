//Updates submit button if user wants to score as well
function updateSubmitButton(){
    if (document.getElementById('doScoring').checked == true) {
        document.getElementById('nsubmit').innerHTML = 'Normalize and score'
    } else {
        document.getElementById('nsubmit').innerHTML = 'Normalize'
    }
}

//Toggles a div element - hide or show
function toggleDiv(checkbox, div){
    if (document.getElementById(checkbox).checked == true) {
        document.getElementById(div).style.display = ''
    } else {
        document.getElementById(div).style.display = 'none'
    }
}


//Triggers help modal/updates content
function labelHelpClicked(containerId){
    document.getElementById('helpModal-heading').innerHTML = "Help me!"
    $('#helpModal-body').load('/assets/help/help-containers.html #'+containerId);
}

//Triggered when array definition dropdown is changed
function arrayDefChanged(x){
    document.getElementById('viewPlate').style.display = "inline";
    document.getElementById('arrayDefCustomCG').style.display = "inline";
    
	//Custom file case
    if(x.selectedIndex == x.length -1){
        document.getElementById('arrayDefCustomCG').style.display = "inline";
        document.getElementById('viewPlate').style.display = "none";
        //Hide all plate dropdowns
        for(i=1;i<x.length-1;i++){
            var value = x.options[i].text + "-plates";
            document.getElementById(value).style.display = "none";
        }
    }else{
        //Not a custom file selection
        document.getElementById('arrayDefCustomCG').style.display = "none";
		
		//Default value case
        if(x.selectedIndex == 0){
            document.getElementById('viewPlate').style.display = "none";
        }else{
            //We are dealing with a selection which is not custom and not the dropdown label
            var arrayDefValue = x.options[x.selectedIndex].text;
            var plateId = arrayDefValue + "-plates";
            var plateDropdown = document.getElementById(plateId);
            var plateIndex = plateDropdown.selectedIndex;
            var plateValue = plateDropdown.options[plateIndex].text;
            
			//Set ID of hidden input which will be bound to form
			//document.getElementById('arrayDefPredefinedPlateId').value = plateId;
			
			//On all plates, dont need view button/load data
			if(plateIndex == 0){
				document.getElementById('viewPlate').style.display = "none";
			}else{
			
            var link = "/assets/data/array-definitions/"+arrayDefValue+"/"+plateValue;
            
            document.getElementById('helpModal-heading').innerHTML = arrayDefValue + " <small>"+plateValue+"</small>";
            
            $('#helpModal-body').CSVToTable(link,
                                            {
                                            loadingText: 'Loading TSV Data...',
                                            startLine: 5,
                                            separator: "\t",
                                            tableClass:"table table-hover" }
                                            );
			}
            
        }
        
        //Hide all plate dropdowns expect the one that is selected
        for(i=1;i<x.length-1;i++){
            var value = x.options[i].text + "-plates";
			var plateDropdown = document.getElementById(value);
            if(x.selectedIndex == i){
                plateDropdown.style.display = "inline";
				plateDropdown.name = "selectedArrayDefPlate";
            }else{
                plateDropdown.style.display = "none";
				plateDropdown.name = "";
            }
        }
    }
    
}
