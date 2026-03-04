//
// include this in any .asp script by placing an ASP #include directive in a <script> block at the bottom of your HTML
//
// then include the className 'status' in the <td>'s you want to be able to filter.
//


var listOptions = {
		valueNames: ['status']
};

var taskList = new List('tasks', listOptions);
	

function FilterStatus_onClick(htmlElement) {

	var filterButton = document.getElementById('filterButton');

	if (taskList.filtered) {
		
		taskList.filter();
		filterButton.innerHTML = 'Hide Completed Projects';
		
	} else {

		taskList.filter(function(item) {
			
// 			if (item.values().status <= '') {
			if (!item.values().status.includes('Complete')) {
				
				return true;
				
			} else {
				
				return false;
			}
			
		});

		filterButton.innerHTML = 'Show Completed Projects';

	}

}
    
