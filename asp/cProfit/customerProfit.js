	//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function BuildContextMenu( customerID, drillDownType, entityID, parms, e ) {
//-- ------------------------------------------------------------------ -->
//-- "customerID" is the cNote customerID
//-- "drillDownType" indicates the entity type the user clicked on 
//-- "entityID" is the ID of the entity the user clicked on
//-- "parms" is an object containing all drilldown parameters
//-- "e" is the click event
//-- ------------------------------------------------------------------ -->
	
	e.preventDefault();	

	const menu = document.querySelector('.context-menu');
						
	var posX, posY;
	
// 	if (e.pageX || e.pageY) {
// 		posX = e.pageX;
// 		posY = e.pageY - 112;
// 		console.log('Using page coordinates of '+posX+','+posY);
// 	} else if (e.clientX || e.clientY) {
// 		posX = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
// 		posY = e.clientY + document.body.scrollTop  + document.documentElement.scrollTop;
// 		console.log('Using client coordinates of '+posX+','+posY);
// 	} else {
// 		posX = 0;
// 		posY = 0;
// 		console.log('Using default coordinates of '+posX+','+posY);
// 	}

	if (e.clientX || e.clientY) {
		posX = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
		posY = e.clientY + document.body.scrollTop  + document.documentElement.scrollTop - 112;
		console.log('Using client coordinates of '+posX+','+posY);
	} else {
		posX = 0;
		posY = 0;
		console.log('Using default coordinates of '+posX+','+posY);
	}
	
	menu.querySelector('.context-menu__title').textContent = 'Drilldown on ' + entityID + ' by:';
	menu.classList.add('context-menu--active');
	var menuWidth 		= $(menu).width();
	var menuHeight 	= $(menu).height();
	var screenWidth 	= $(window).width();
	var screenHeight 	= $(window).height();
	console.log('screenWidth: ' + screenWidth + '; screenHeight: ' + screenHeight);
	
	if ( menuWidth + posX > screenWidth ) {
		console.log('menu would be off the right of the screen, so shifting left');
		menu.style.left = posX - menuWidth + 'px';
	} else {
		menu.style.left = posX + 'px';
	}

	if ( menuHeight + posY > screenHeight ) {
		console.log('menu would be off the bottom of the screen so shifting up');
		menu.style.top  = posY - menuHeight + 'px';
	} else {
		menu.style.top  = posY + 'px';
	}
	
	
	
	
	// remove all existing events...
	$('li.accounts').off('click');
	$('li.accountHolders').off('click');
	$('li.branches	').off('click');
	$('li.officers').off('click');
	$('li.products').off('click');					

	// convert "parms" object to string for the querystrings...
	var querystringParms = '';
	if ( parms.account != null) {
		querystringParms += '&account='+parms.account;
	}
	if ( parms.accountHlolder != null) {
		querystringParms += '&accountHolder='+parms.accountHolder;
	}
	if ( parms.branch != null) {
		querystringParms += '&branch='+parms.branch;
	}
	if ( parms.officer != null) {
		querystringParms += '&officer='+parms.officer;
	}
	if ( parms.product != null) {
		querystringParms += '&product='+parms.product;
	}
	
	// add new event listeners...
	$('li.accounts').on('click', function() {
		window.location.href = '/cProfit/accountSummary.asp?customerID='+customerID+'&'+drillDownType+'='+entityID + querystringParms;
	});
	$('li.accountHolders').on('click', function() {
		window.location.href = '/cProfit/accountHolderSummary.asp?customerID='+customerID+'&'+drillDownType+'='+entityID + querystringParms;
	});
	$('li.branches').on('click', function() {
		window.location.href = '/cProfit/branchSummary.asp?customerID='+customerID+'&'+drillDownType+'='+entityID + querystringParms;
	});
	$('li.officers').on('click', function() {
		window.location.href = '/cProfit/officerSummary.asp?customerID='+customerID+'&'+drillDownType+'='+entityID + querystringParms;
	});
	$('li.products').on('click', function() {
	window.location.href = '/cProfit/productSummary.asp?customerID='+customerID+'&'+drillDownType+'='+entityID + querystringParms;
	});
	
	// hide the LI for the current drillDownType...

	if ( drillDownType == 'account') {
		$('li.accounts').hide();
	}
	if ( drillDownType == 'accountHolder') {
		$('li.accountHolders').hide();
	}
	if ( drillDownType == 'branch') {
		$('li.branches').hide();
	}
	if ( drillDownType == 'officer') {
		$('li.officers').hide();
	}
	if ( drillDownType == 'product') {
		$('li.products').hide();
	}
	
	
	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
async function DeleteAccountHolderComment(deleteIconElem,mainDataTable) {
//-- ------------------------------------------------------------------ -->
//--	
//-- this deletes an existing comment from accountHolderAddenda...
//--	

	if ( confirm('Are you sure you want to delete this comment? \n\nThis cannot be undone.') ) {
	
		const commentID 	= deleteIconElem.getAttribute('data-id');	
		const url 			= '/ajax/accountHolderComments.asp?id=' + commentID;
		
		const apiResponse = await fetch(url, {
			method: 'DELETE'
		});
		
		if (apiResponse.status !== 200) {
			return generateErrorResponse('Failed to fetch API details ' + apiResponse.status);
		}
		
		var apiResult = await apiResponse.json();
		
		const targetAuthorRow = deleteIconElem.closest('tr');
		const targetTable = targetAuthorRow.closest('table');
		const targetCommentRow = targetAuthorRow.nextSibling;
		
		targetTable.deleteRow(targetCommentRow.rowIndex);
		targetTable.deleteRow(targetAuthorRow.rowIndex);
		
// 		UpdateAddendaIndicator(mainDataTable);
		UpdateAddendaIndicator(mainDataTable);
		
		if ( apiResult.msg ) {
			const notification = document.querySelector('.mdl-js-snackbar');
			notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});
		}
		

	} else {
		
		return false;
		
	}
	
}
//-- ------------------------------------------------------------------ -->

	
//-- ------------------------------------------------------------------ -->
async function SaveNewAccountHolderComment(accountHolderNumber, customerID, newComment, mainDataTable) {
//-- ------------------------------------------------------------------ -->
//--	
//-- this saves a new comment to accountHolderAddenda...
//--	

	var url 	= '/ajax/accountHolderComments.asp';
	var form = 'accountHolderNumber=' + accountHolderNumber 
							+ '&customerID=' + customerID 
							+ '&newComment=' + encodeURIComponent(newComment);

	const apiResponse = await fetch(url, {
		method: 'POST',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form
	});
	
	if (apiResponse.status !== 200) {
		return generateErrorResponse('Failed to fetch API details ' + apiResponse.status);
	}
	
	var apiResult = await apiResponse.json();


	const menu = document.querySelector('div.cNoteShowAddendaContextMenu');
	const commentTable = menu.querySelector('table.accountHolderComments');

	//-- first add the comment into the first row of the table, then add the author row...

	const newCommentRow = commentTable.insertRow(0);
	const newAuthorRow = commentTable.insertRow(0);
	
	const authorTD 	= document.createElement('td');
	const authorName 	= document.createTextNode(apiResult.author);
	const timeStampTD = document.createElement('td');
	const fromNow 		= document.createTextNode(moment(apiResult.udpatedDateTime).fromNow());
	const deleteTD		= document.createElement('td');
	const deleteIcon	= document.createElement('i');

	authorTD.style.fontWeight = 'bold';
	authorTD.style.textAlign = 'left';
	authorTD.style.border = 'none';
	authorTD.style.flex = '1';
	authorTD.style.display = 'inline-block';
	authorTD.appendChild(authorName);
	newAuthorRow.appendChild(authorTD);
	
	timeStampTD.style.fontStyle = 'italic';
	timeStampTD.style.fontSize = 'smaller';
	timeStampTD.style.textAlign = 'right';
	timeStampTD.style.border = 'none';
	timeStampTD.appendChild(fromNow);
	newAuthorRow.appendChild(timeStampTD);					
	
	deleteIcon.classList.add('material-icons');
	deleteIcon.classList.add('delete');
	deleteIcon.setAttribute('data-id',apiResult.id);
	deleteIcon.style.verticalAlign = 'middle';
	deleteIcon.style.visibility = 'hidden';
	deleteIcon.innerHTML = 'delete';

	deleteIcon.addEventListener('click', function() {
		var table = $('#cNoteTableTop').DataTable();
		DeleteAccountHolderComment(this,table);
	})


	
	deleteTD.appendChild(deleteIcon);
	deleteTD.style.border = 'none';

	newAuthorRow.style.display = 'flex';
	newAuthorRow.style.alignItems = 'stretch';
	newAuthorRow.appendChild(deleteTD);

	newAuthorRow.addEventListener('mouseover', function() {
		
		var deleteIcon = this.querySelector('i.delete');
		if (deleteIcon) {
			if (deleteIcon.style.visibility == 'hidden') {
				deleteIcon.style.visibility = 'visible';
			} else {
				deleteIcon.style.visibility = 'hidden';
			}
		}

	});

	newAuthorRow.addEventListener('mouseout', function() {

		var deleteIcon = this.querySelector('i.delete');
		if (deleteIcon) {
			if (deleteIcon.style.visibility == 'hidden') {
				deleteIcon.style.visibility = 'visible';
			} else {
				deleteIcon.style.visibility = 'hidden';
			}
		}

	});


	
	const commentTD = document.createElement('td');
	const commentText = document.createTextNode(apiResult.content);
	commentTD.colSpan = 3;
	commentTD.style.paddingBottom = '10px';
	commentTD.style.border = 'none';
	commentTD.appendChild(commentText);
	newCommentRow.appendChild(commentTD);
	
	
	// be sure to clear out the contents of the comment input field....
	const newComments = document.querySelectorAll('textarea.newComment');
	if (newComments) {
		for (i = 0; i < newComments.length; ++i) {
			newComments[i].value = '';
		}
	}
	
	// be sure to disable the cancel/edit buttons, too...
	menu.querySelector('button.cancel').disabled = true;
	menu.querySelector('button.save').disabled = true;
	
	if ( apiResult.msg ) {
		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});
	}


	UpdateAddendaIndicator(mainDataTable);

	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function UpdateAddendaIndicator(dataTable) {
//-- ------------------------------------------------------------------ -->
//-- updated the flag/comment indicator on the main page....
//-- first, find the highest priority flag (if there is one)...
//-- ------------------------------------------------------------------ -->


	const addendaPopup = document.querySelector('div.cNoteShowAddendaContextMenu');
	const accountHolderNumber = addendaPopup.id;

	const flagList = addendaPopup.querySelector('ul.accountHolderFlags');
	const flagSelectors = flagList.querySelectorAll('i.flagSelector');

	var iconToShow, iconToShowColor, iconToShowClass;

	if (flagSelectors) {
		for (i = 0; i < flagSelectors.length; ++i) {
			if (flagSelectors[i].textContent == 'check') {
				iconToShow = 'flag';
				iconToShowColor = flagSelectors[i].nextSibling.style.color;
				iconToShowClass = '';
				break;
			}
		}
	}
	
	// if no flag, look for a comment...
	if (!iconToShow) {
		const commentTable = addendaPopup.querySelector('table.accountHolderComments');
		const commentRows = commentTable.querySelectorAll('tr');
		if (commentRows.length > 0) {
			iconToShow = 'notes';
			iconToShowColor = '';
			iconToShowClass = '';
		}
	}

	// if still no flag, then show an "add" button....
	if (!iconToShow) {
		iconToShow = "add";
		iconToShowColor = '';
		iconToShowClass = 'add';
	}
		

	// finally, find and update the row on the main table...
	var mainTableCell = dataTable.cell('#'+accountHolderNumber,'.addenda');
	mainTableCell.data('<button class="mdl-button mdl-js-button mdl-button--icon addenda '+iconToShowClass+'"><i class="material-icons" style="color:'+iconToShowColor+'">'+iconToShow+'</i></button>')

	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
async function EditAccountHolderAddenda(htmlElement, popupMenu, mainDataTable) {
//-- ------------------------------------------------------------------ -->
//--	
//-- this call fetches any addenda for the customer associated with htmlElement..
//--	
	

// 	var accountHolderNumber 	= htmlElement.id;
	var accountHolderNumber 	= htmlElement.closest('tr').id;
	
	if ( htmlElement.querySelector('.accountHolderName').classList.contains('is-upgraded') ) {
		var accountHolderName = htmlElement.querySelector('.accountHolderName').textContent;
	} else {
		var accountHolderName = '<i class="material-icons">portrait</i>';
	}
 	

	var cProfitAddenda 		= '/ajax/accountHolderAddenda.asp?'
												+ 'customerID=' + customerID 
												+ '&accountHolderNumber=' + accountHolderNumber;

	const addendaResponse = await fetch(cProfitAddenda);
	if (addendaResponse.status !== 200) {
		return generateErrorResponse('Failed to fetch account holder addenda ' + addenda.status);
	}
	const addendaResult = await addendaResponse.json();

	// populate the dialog...
	
	if (addendaResult.flags) {
		
		// populate the popup...
		
		popupMenu.id = accountHolderNumber;
		popupMenu.setAttribute('data-customerID', customerID);
		
		var flagList = popupMenu.querySelector('.accountHolderFlags');
		flagList.innerHTML = '';

		for (i = 0; i < addendaResult.flags.length; ++i) {

			var newLI = document.createElement('li');

			var newCheckIcon = document.createElement('i');
			newCheckIcon.classList.add('material-icons');
			newCheckIcon.classList.add('flagSelector');
			newCheckIcon.style.verticalAlign = 'middle';
			newCheckIcon.style.width = '24px';
			newCheckIcon.innerHTML = addendaResult.flags[i].checked;	
			newLI.appendChild(newCheckIcon);

			var newFlagIcon = document.createElement('i');
			newFlagIcon.classList.add('material-icons');
			newFlagIcon.classList.add('flag');
			newFlagIcon.setAttribute('data-flagID', addendaResult.flags[i].id);
			newFlagIcon.style.color = addendaResult.flags[i].color;
			newFlagIcon.style.verticalAlign = 'middle';
			newFlagIcon.style.cursor = 'pointer';
			newFlagIcon.innerHTML = 'flag';	
			newLI.appendChild(newFlagIcon);
			
			newLI.addEventListener('click', function(){
				var selectorIcon = this.closest('li').querySelector('i.flagSelector');
				if (selectorIcon.innerHTML) {
					selectorIcon.innerHTML = '';
				} else {
					selectorIcon.innerHTML = 'check';
				}
				var accountHolderNumber = this.closest('div.cNoteAddendaContextMenu').id;
				var flagColor = this.querySelector('.flag').textContent;
				var flagID = this.querySelector('.flag').getAttribute('data-flagID');
				UpdateAccountHolderFlag(accountHolderNumber, customerID, flagID);
				
				
				UpdateAddendaIndicator(mainDataTable);
				
				
				
				
			});

			var flagName = document.createTextNode(addendaResult.flags[i].name);
			newLI.appendChild(flagName);				
			
			flagList.appendChild(newLI);			

		}
		
		// always add one more item to the list to add a new flag/label....
		
		var newLI = document.createElement('li');

		var newCheckIcon = document.createElement('i');
		newCheckIcon.classList.add('material-icons');
		newCheckIcon.style.verticalAlign = 'middle';
		newCheckIcon.style.width = '24px';
		newCheckIcon.innerHTML = '';	
		newLI.appendChild(newCheckIcon);

		var newFlagIcon = document.createElement('i');
		newFlagIcon.classList.add('material-icons');
		newFlagIcon.style.verticalAlign = 'middle';
		newFlagIcon.innerHTML = 'add';	
		newLI.appendChild(newFlagIcon);

		var flagName = document.createTextNode('Add new flag/label');
		newLI.appendChild(flagName);				
		
		flagList.appendChild(newLI);			

	} 

	
	const commentsDiv = popupMenu.querySelector('.accountHolderLastComment');
	const timeFromNowElem = popupMenu.querySelector('.timeFromNow');

	if (addendaResult.comments) {
		
		const commentsTable = popupMenu.querySelector(".accountHolderComments");
		commentsTable.innerHTML = '';
		
		for (i = 0; i < addendaResult.comments.length; ++i) {
			
			const newAuthorRow = document.createElement('tr');
			newAuthorRow.style.display = 'flex';
			newAuthorRow.style.alignItems = 'stretch';

			const newHeaderAuthorCell 	= document.createElement('td');
			const newHeaderAuthorText 	= document.createTextNode(addendaResult.comments[i].updatedBy);
			
			newHeaderAuthorCell.appendChild(newHeaderAuthorText);
			newHeaderAuthorCell.style.fontWeight = 'bold';
			newHeaderAuthorCell.style.textAlign = 'left';
			newHeaderAuthorCell.style.border = 'none';
			newHeaderAuthorCell.style.flex = '1';
			newHeaderAuthorCell.style.display = 'inline-block';
			newAuthorRow.appendChild(newHeaderAuthorCell);

			const newHeaderFromNowCell = document.createElement('td');
			const newHeaderFromNowText = document.createTextNode(moment(addendaResult.comments[i].updatedDateTime).fromNow());
			newHeaderFromNowCell.style.fontStyle = 'italic';
			newHeaderFromNowCell.style.fontSize = 'smaller';
			newHeaderFromNowCell.style.textAlign = 'right';
			newHeaderFromNowCell.style.border = 'none';
			newHeaderFromNowCell.appendChild(newHeaderFromNowText);
			newAuthorRow.appendChild(newHeaderFromNowCell);
			
			const newDeleteCommentCell = document.createElement('td');
			newDeleteCommentCell.style.border = 'none';
			newDeleteCommentCell.style.float = 'right';

			const newDeleteIcon = document.createElement('i');
			newDeleteIcon.classList.add('material-icons');
			newDeleteIcon.classList.add('delete');
			newDeleteIcon.style.verticalAlign = 'middle';
			newDeleteIcon.style.visibility = 'hidden';
			newDeleteIcon.setAttribute('data-id', addendaResult.comments[i].id);
			newDeleteIcon.innerHTML = 'delete';
			
			newDeleteIcon.addEventListener('click', function() {
				DeleteAccountHolderComment(this,mainDataTable);
			})

			newAuthorRow.addEventListener('mouseover', function() {
				
				var deleteIcon = this.querySelector('i.delete');
				if (deleteIcon) {
					if (deleteIcon.style.visibility == 'hidden') {
						deleteIcon.style.visibility = 'visible';
					} else {
						deleteIcon.style.visibility = 'hidden';
					}
				}

			});

			newAuthorRow.addEventListener('mouseout', function() {

				var deleteIcon = this.querySelector('i.delete');
				if (deleteIcon) {
					if (deleteIcon.style.visibility == 'hidden') {
						deleteIcon.style.visibility = 'visible';
					} else {
						deleteIcon.style.visibility = 'hidden';
					}
				}

			});
			newDeleteCommentCell.appendChild(newDeleteIcon);
			newAuthorRow.appendChild(newDeleteCommentCell);

			newAuthorRow.appendChild(newDeleteCommentCell);						
			
			commentsTable.appendChild(newAuthorRow);

			
			const newContentRow = document.createElement('tr');
			const newContentCell = document.createElement('td');
			newContentCell.colSpan = '3';
			newContentCell.style.paddingBottom = '12px';
			newContentCell.style.border = 'none';
			newContentCell.style.width = '24px';
			const newContentText = document.createTextNode(addendaResult.comments[i].content);
			newContentCell.appendChild(newContentText);
			newContentRow.appendChild(newContentCell);
			
			commentsTable.appendChild(newContentRow);

		}

	}
		
	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
async function UpdateAccountHolderFlag (accountHolderNumber, customerID, flagID) {
//-- ------------------------------------------------------------------ -->
	
	const url = '/ajax/accountHolderAddenda.asp';

	const form = 'accountHolderNumber=' + accountHolderNumber + '&customerID=' + customerID + '&flagID=' + flagID;

	const apiResponse = await fetch(url, {
		method: 'POST',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form
	});
	
	if (apiResponse.status !== 200) {
		return generateErrorResponse('Failed to fetch API details ' + apiResponse.status);
	}
	
	const apiResult = await apiResponse.json();
	
	if ( apiResult.msg ) {
		const notification = document.querySelector('.mdl-js-snackbar');
		notification.MaterialSnackbar.showSnackbar({message: apiResult.msg});
	}

	return apiResult;

}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
async function Get_cProfitApiDetails( customerID ) {
//-- ------------------------------------------------------------------ -->
//
//	  This call fetches the API Key for the customer and the cProfit URI
//
	let accessInfo;
	
	await $.ajax({
		url: `${apiServer}/api/customers/cprofitAccessInfo/${customerID}`,
		headers: { 'Authorization': 'Bearer ' + sessionJWT },
	}).then( function( response ) {
		accessInfo = response;
	}).fail( function( req, status, err ) {
		console.log( 'cProfit PII API access detail could not be retreived' );
	});

	return accessInfo;

/*
	const cProfitDetails = '/cProfit/getApiDetails.asp?customerID=' + customerID;
	const apiResponse = await fetch(cProfitDetails);
	if (apiResponse.status !== 200) {
		return generateErrorResponse('Failed to fetch API details ' + apiResponse.status);
	}
	const apiResult = await apiResponse.json();

	return apiResult;
*/
	
	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
async function GetAccountDetails( customerID ) {
//-- ------------------------------------------------------------------ -->

	const apiDetails = await Get_cProfitApiDetails( customerID );
	const key 			= apiDetails.cProfitApiKey;
	const url 			= apiDetails.cProfitURI;
	const acct 			= $( '.accountNumber' ).parent()[0].id;

	// check "cProfit PII Server Status Emulation" in System Controls....
	let currentStatus = await GetPiiServerStatus( url, key );
	if ( currentStatus != 'enabled' ) {
		$( '.accountNumber' ).html( acct );
		return false;
	}


	$.ajax({

		url: `${url}/accounts/${acct}`,
		headers: { 'apikey': key }

	}).then( function( response ) {
		
		$( '.accountNumber' ).html( response.account_number );
		
		let fullName = response.last_name;
		fullName = response.first_name ? fullName += ', ' + response.first_name : fullName;
		fullName = response.middle_name ? fullName += ' ' + response.middle_name : fullName;
		let fullNameAddress = fullName;
		fullNameAddress = response.address_1 ? fullName += '<br>'+response.address_1 : fullNameAddress;
		fullNameAddress = response.address_2 ? fullName += '<br>'+response.address_2 : fullNameAddress;
		fullNameAddress = response.city ? fullName += '<br>'+response.city : fullNameAddress;
		fullNameAddress = response.state ? fullName += '&nbsp;'+response.state : fullNameAddress;
		fullNameAddress = response.zip_code ? fullName += '&nbsp;'+response.zip_code : fullNameAddress;
		$( '.accountHolderNameAddress').html( fullNameAddress );
		$( '.accountHolderNumber').html( response.cif );
		$( '.accountPhone').html( response.phone );
		$( '.accountEmail').html( response.email );


		
	}).fail( function( req, status, err ) {
		console.warn( 'Account details could not be retrieved' );
	});

}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
async function GetAllVisibleAccounts(customerID) {
//-- ------------------------------------------------------------------ -->

	var allAccountElems = document.querySelectorAll('.accountNumber');
	if ( allAccountElems.length <= 0 ) {
		return false;
	}
	
	
	var cNoteTable 				= document.querySelector('table.cNoteTable');
	var cNoteTableBody 			= cNoteTable.querySelector('tbody');
	var viewPortBounds			= cNoteTableBody.getBoundingClientRect();
	
	var actualViewPortTop		= viewPortBounds.top;
	var actualViewPortBottom	= viewPortBounds.top + viewPortBounds.height;
	
	var viewPortMargin = 30 * 10;
	
	var viewPortTop				= actualViewPortTop - viewPortMargin;
	var viewPortBottom			= actualViewPortBottom + viewPortMargin;

	var accounts 			= [];
	var urlValues 			= '';
	var firstTime 			= true;
		
		
	for ( i = 0; i < allAccountElems.length; ++i) {
		
		if ( allAccountElems[i].nodeName == 'TD') {
		
			if ( !allAccountElems[i].classList.contains('is-upgraded') ) {
			
				var bounding 			= allAccountElems[i].getBoundingClientRect();
				var boundingTop 		= bounding.top;
				var boundingBottom 	= bounding.top + bounding.height;
				
				if ( (boundingBottom >= viewPortTop && boundingTop <= viewPortBottom) || (boundingTop >= viewPortBottom && boundingBottom <= viewPortTop) ) {
	
					var accountID = allAccountElems[i].parentNode.id;

					accounts.push(accountID);
					urlValues += accountID
					if (i+1 < allAccountElems.length) {
						urlValues += ',';
					}
				}
				
			}
			
		} else {
			
			var accountID = allAccountElems[i].parentNode.id;

			accounts.push(accountID);
			if (urlValues.length > 0) {
				urlValues += ',';
			}
			urlValues += accountID;
			
		}

	}


	var apiDetails = await Get_cProfitApiDetails(customerID);
	var key = apiDetails.key;
	var url = apiDetails.uri + '/accounts.asp?cmd=searchList';

	var form = '';
	for (i = 0; i < accounts.length; ++i) {
	
		if (i > 0) {
			form += ',';
		} else {
			form = 'accounts=';
		}
		form += accounts[i];
		
	}
	form += '&key=' + key;

	var options = {
		method: 'POST',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form	
	}

	const response = await fetch(url,options);


	
	if (response.status !== 200) {
		return generateErrorResponse('The server responded with an unexpected status' + response.status);
	}

	const result = await response.json();
	
	Object.keys(result).forEach(function(key) {
		
		var hashed_account 	= key;
		var account_number	= result[key].account_number;
		var cif					= result[key].cif;
		var first_name 		= result[key].first_name;
		var middle_name 		= result[key].middle_name;
		var last_name 			= result[key].last_name;
		
		
		var fullName 			= last_name;
		if (first_name.length > 0) {
			fullName += ', ' + first_name;
			if (middle_name.length > 0) {
				fullName += ' ' + middle_name;
			}
		}
		
		var targetElem = document.getElementById(hashed_account);
		if (targetElem) {
			
			var accountHolderElem = targetElem.querySelector('.accountHolderNumber');
			if (accountHolderElem) {
				accountHolderElem.innerHTML = cif;
			}

			var accountHolderNameElem = targetElem.querySelector('.accountHolderName');
			if (accountHolderNameElem) {
				accountHolderNameElem.innerHTML = fullName;
			}

			var accountNumberElem = targetElem.querySelector('.accountNumber');
			if (accountNumberElem) {
				accountNumberElem.innerHTML = account_number;
			}

			targetElem.classList.add('is-upgraded');

		}
		
	})

}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
// OBVIATED??
async function GetAllVisibleAccountHolders(customerID) {
//-- ------------------------------------------------------------------ -->

	var allAccountHolderTDs = document.querySelectorAll('.accountHolderNumber');
	if ( allAccountHolderTDs.length <= 0 ) {
		return false;
	}
	
	var cNoteTable 		= document.querySelector('table.cNoteTable');
	var cNoteTableBody 	= cNoteTable.querySelector('tbody');
	var viewPortBounds	= cNoteTableBody.getBoundingClientRect();
	
	var actualViewPortTop		= viewPortBounds.top;
	var actualViewPortBottom	= viewPortBounds.top + viewPortBounds.height;
	
	var viewPortMargin = 30 * 10;
	
// 	var viewPortTop				= actualViewPortTop - Math.floor(actualViewPortTop / 8);
// 	var viewPortBottom			= actualViewPortBottom + Math.floor(actualViewPortBottom / 8);
	var viewPortTop				= actualViewPortTop - viewPortMargin;
	var viewPortBottom			= actualViewPortBottom + viewPortMargin;

	var accountHolders = [];
	var urlValues = '';
	var firstTime = true;
		
		
	for ( i = 0; i < allAccountHolderTDs.length; ++i) {
		
		if ( !allAccountHolderTDs[i].classList.contains('is-upgraded') ) {
		
			var bounding 			= allAccountHolderTDs[i].getBoundingClientRect();
			var boundingTop 		= bounding.top;
			var boundingBottom 	= bounding.top + bounding.height;
			
			if ( (boundingBottom >= viewPortTop && boundingTop <= viewPortBottom) || (boundingTop >= viewPortBottom && boundingBottom <= viewPortTop) ) {
// 				console.log('td is in view');
				accountHolders.push(allAccountHolderTDs[i].closest('tr').id);
				urlValues += allAccountHolderTDs[i].closest('tr').id
				if (i+1 < allAccountHolderTDs.length) {
					urlValues += ",";
				}
			}
			
		}

	}


	var apiDetails = await Get_cProfitApiDetails(customerID);
	var key = apiDetails.key;
	var url = apiDetails.uri + '/accountHolders.asp?cmd=searchList';

	var form = '';
	for (i = 0; i < accountHolders.length; ++i) {
	
		if (i > 0) {
			form += ',';
		} else {
			form = 'cif_hash=';
		}
		form += accountHolders[i];
		
	}
	form += '&key=' + key;

	var options = {
		method: 'POST',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form	
	}

		
	const response = await fetch(url,options);

	if (response.status !== 200) {
		return generateErrorResponse('The server responded with an unexpected status' + response.status);
	}
	

	const result = await response.json();
	
	Object.keys(result).forEach(function(key) {
		
		var cif_hash 		= key;
		var cif				= result[key].cif;
		var first_name 	= result[key].first_name;
		var middle_name 	= result[key].middle_name;
		var last_name 		= result[key].last_name;

		var fullName 			= last_name;
		if (first_name.length > 0) {
			fullName += ', ' + first_name;
			if (middle_name.length > 0) {
				fullName += ' ' + middle_name;
			}
		}

		var tableRow = document.getElementById(cif_hash);
		
		var accountHolderNumberCell = tableRow.querySelector('.accountHolderNumber');
		if(accountHolderNumberCell) {
			accountHolderNumberCell.innerHTML = cif;
			accountHolderNumberCell.classList.add('is-upgraded');
		}
		
		var accountHolderNameCell = tableRow.querySelector('.accountHolderName');
		if (accountHolderNameCell) {
			accountHolderNameCell.innerHTML = fullName;
			accountHolderNameCell.classList.add('is-upgraded');
		}
		
		var accountNumberCell = tableRow.querySelector('.accountNumber');
		if (accountNumberCell) {
			accountNumberCell.innerHTML = accountNumber;
			accountNumberCell.classList.add('is-upgraded');
		}

		var accountHolderNameAddress = document.querySelector('.accountHolderNameAddress');
		if (accountHolderNameAddress) {
	
			var fullName = last_name;
			if (first_name.length > 0) {
				fullName += ', ' + first_name;
				if (middle_name.length > 0) {
					fullName += ' ' + middle_name;
				}
			}
	
			accountHolderNameAddress = fullName;
			if (address_1) {
				accountHolderNameAddress += '<br>' + address_1;
			}
			if (address_2) {
				accountHolderNameAddress += '<br>' + address_2;
			}
			if (city) {
				accountHolderNameAddress += '<br>' + city;
			}
			if (state) {
				accountHolderNameAddress += '&nbsp;' + state;
			}
			if (zip_code) {
				accountHolderNameAddress += '&nbsp;' + zip_code;
			}
	
			accountHolderNameAddress.innerHTML = accountHolderNameAddress;
			
		}
		
	

		
		
	})

}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
async function GetPiiServerStatus( url, key ) {
//--------------------------------------------------------------------------------------------


	await $.ajax({
		url: `${url}/ping`,
		headers: { 'apikey': key }
	}).then( function( response ) {
		if ( sessionStorage.getItem( 'apiStatus' ) === 'disabled' ) {
			
			returnValue = 'disabled';
			
		} else {
			returnValue = 'enabled';
		}
	}).fail( function( req, status, err ) {

		returnValue = 'disabled';

	});
	
	return returnValue;



// 	try {
// 
// 		const apiResponse = await fetch( 'ajax/systemControls.asp?name=cProfit PII Server Status Emulation' );
// 		if ( apiResponse.status != 200 ) {
// 			return generateErrorResponse('Failed to get PII Server Status, ' + apiResponse.status);
// 		}			
// 		const apiResult = await apiResponse.json();
// 		
// 		const responseName = apiResult.name;
// 		const responseValue = apiResult.value;
// 		
// 		return responseValue;
// 
// 	} catch( err ) {
// 		console.error( 'Unexpected error in GetPiiServerStatus: ' + err );
// 		return 'error';
// 	}
				
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
async function GetAllAccountsInDatatable( datatable, customerID ) {
//-- ------------------------------------------------------------------ -->

	const apiDetails = await Get_cProfitApiDetails( customerID );
	const key 			= apiDetails.cProfitApiKey;
	const url 			= apiDetails.cProfitURI;

	// check "cProfit PII Server Status Emulation" in System Controls....
	let currentStatus = await GetPiiServerStatus( url, key );
	if ( currentStatus != 'enabled' ) {
		return false;
	}

	const accounts 	= datatable.rows().ids().toArray();
	
//	const apiDetails 	= await Get_cProfitApiDetails(customerID);
//	const key 			= apiDetails.key;

	for ( acct of accounts ) {

		$.ajax({
			url: `${url}/accounts/${acct}`,
			headers: { 'apikey': key }
		}).then( function( response ) {
			
			let accountNumberCell = datatable.cell( '#'+response.account_hash, '.accountNumber' );
			accountNumberCell.data( response.account_number );
			accountNumberCell.node().classList.add( 'is-upgraded' );
			
		}).fail( function( req, status, err ) {

			console.warn( 'Account details could not be retrieved' );

		});

	}

}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
async function GetAllAccountHoldersInDatatable( datatable, customerID ) {
//-- ------------------------------------------------------------------ -->

	// check "cProfit PII Server Status Emulation" in System Controls....
	let currentStatus = await GetPiiServerStatus( cProfitURL, cProfitApiKey );

	// determine if "datatable" has an accountHolderName column....
	let accountHoldersPresent = false;
	const columns = datatable.columns().dataSrc();
	
	for ( col in columns ) {
		if ( col = 'accountHolderNumber' ) {
			accountHoldersPresent = true;
			break;
		}
	}
	
	if ( accountHoldersPresent && currentStatus === 'enabled' ) {
		$( 'button.dt-button' ).show();
		$( datatable.column( '.accountHolderToken' ).visible( false ) );
		$( datatable.column( '.accountHolderNumber' ).visible( true ) );
		$( datatable.column( '.accountHolderName' ).visible( true ) );
	} else {
		// there is no reason to show "number" or "name" because it will always
		// have the same value as "token" -- so just show "token"
		$( 'button.dt-button' ).hide();
		$( datatable.column( '.accountHolderToken' ).visible( true ) );
		$( datatable.column( '.accountHolderNumber' ).visible( false ) );
		$( datatable.column( '.accountHolderName' ).visible( false ) );
		return false;
	}
	

	const accountHolders = datatable.rows().ids().toArray();

	const apiDetails = await Get_cProfitApiDetails( customerID );
	const key 			= apiDetails.cProfitApiKey;
	const url 			= apiDetails.cProfitURI;

	for ( acctHolder of accountHolders ) {
	
		$.ajax({
			url: `${url}/accountHolders/${acctHolder}`,
			headers: { 'apikey': key }
		}).then( function( response ) {
			
			let fullName 	= response.last_name;
			fullName 		= response.first_name  ? fullName += ', ' + response.first_name  : fullName;
			fullName 		= response.middle_name ? fullName += ' '  + response.middle_name : fullName;
			
			let acctHolderNameCell = datatable.cell( '#'+response.cif_hash, '.accountHolderName' );
			acctHolderNameCell.data( fullName );
			acctHolderNameCell.node().classList.add( 'is-upgraded' );
			
			let acctHolderNumberCell = datatable.cell( '#'+response.cif_hash, '.accountHolderNumber' );
			acctHolderNumberCell.data( response.cif );
			acctHolderNumberCell.node().classList.add( 'is-upgraded' );

		}).fail( function( req, status, err ) {
			console.warn( 'Account holder could not be retrieved' );
		});

	}
			
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
async function GetAllAccountHolders(customerID) {
//-- ------------------------------------------------------------------ -->
//
// this function is used to get all accountHolders that might be on a page.
// if you want to find accountHolders in a jQuery DataTable, use the 
// companion function "GetAllAccountHolderInDatatable:
	
	var allAccountHolderElems = document.querySelectorAll('.accountHolderNumber');
	if ( allAccountHolderElems.length <= 0 ) {
		return false;
	}
	
	var accountHolders 	= [];
	var urlValues 			= '';		
		
	for ( i = 0; i < allAccountHolderElems.length; ++i) {
		
		var accountHolderID = allAccountHolderElems[i].parentNode.id;
		
		accountHolders.push(accountHolderID);
		urlValues += accountHolderID;
		if ( i+1 < allAccountHolderElems.length ) {
			urlValues += ",";
		}
		
	}


	var apiDetails = await Get_cProfitApiDetails(customerID);
	var key 			= apiDetails.key;
	var url 			= apiDetails.uri + '/accountHolders.asp?cmd=searchList';

	var form = '';
	for ( i = 0; i < accountHolders.length; ++i ) {
	
		if ( i > 0 ) {
			form += ',';
		} else {
			form = 'cif_hash=';
		}
		form += accountHolders[i];
		
	}
	form += '&key=' + key;

	var options = {
		method: 'POST',
		headers: {
			'Content-type': 'application/x-www-form-urlencoded'
		},
		body: form	
	}

	const response = await fetch(url,options);


	
	if (response.status !== 200) {
		return generateErrorResponse('The server responded with an unexpected status' + response.status);
	}

	const result = await response.json();

	
	Object.keys(result).forEach(function(key) {
		
		var cif_hash 		= key;
		var cif				= result[key].cif;
		var first_name 	= result[key].first_name;
		var middle_name 	= result[key].middle_name;
		var last_name 		= result[key].last_name;

		var fullName 			= last_name;
		if (first_name.length > 0) {
			fullName += ', ' + first_name;
			if (middle_name.length > 0) {
				fullName += ' ' + middle_name;
			}
		}

		
		// look for accountHolders...
		accountHolderElem = document.getElementById(cif_hash);
		if ( accountHolderElem ) {

			var accountHolderNumberElem = accountHolderElem.querySelector('.accountHolderNumber');
			if ( accountHolderNumberElem ) {
				accountHolderNumberElem.textContent = cif;
			}
			var accountHolderNameElem = accountHolderElem.querySelector('.accountHolderName');
			if ( accountHolderNameElem ) {
				accountHolderNameElem.textContent = fullName;			
			}

		}
		
		
	});
	

		
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function HightLightCMItem () {
//-- ------------------------------------------------------------------ -->
	
	var itemClassList = this.classList; 
	
	if (itemClassList) {
		
			if (itemClassList.contains('cNoteHighlightedCMItem')) {
				itemClassList.remove('cNoteHighlightedCMItem');
			} else {
				itemClassList.add('cNoteHighlightedCMItem');
			}
			
			this.style.cursor = 'pointer';
			
	}

}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function HighlightItem () {
//-- ------------------------------------------------------------------ -->
	
	var itemClassList = this.classList; 
	
	if (itemClassList) {
		
			if (itemClassList.contains('cNoteHighlightedCell')) {
				itemClassList.remove('cNoteHighlightedCell');
			} else {
				itemClassList.add('cNoteHighlightedCell');
			}
			
			this.style.cursor = 'context-menu';
			
	}

}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function DrillDown_ClassBranch () {
//-- ------------------------------------------------------------------ -->

	var groupName;
	if ( this.classList.contains('loan') ) {
		groupName = 'loan';
	} else if ( this.classList.contains('deposit') ) {
		groupName = 'deposit';
	} else {
		groupName = 'other';
	}
	
	var branchName = this.parentNode.id;
	
	console.log('Clicked On - group: ' + groupName + ', branch: ' + branchName);	


}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function HighlightRow () {
//-- ------------------------------------------------------------------ -->
	
	var rowClassList = this.classList;
	
	if (this.classList) {
		
			if (this.classList.contains('cNoteHighlightedCell')) {
				this.classList.remove('cNoteHighlightedCell');
			} else {
				this.classList.add('cNoteHighlightedCell');
			}
			
	}

	accountHolderTD = this.querySelector('td.accountHolder');
// 	AccountHolder_onClick(accountHolderTD);


}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function generateErrorResponse(message) {
//-- ------------------------------------------------------------------ -->

	return {
		status : 'error',
		message
	};

}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function DrillDownOnLDO(customerID,htmlElement,clickedRow,clickedColumn) {
//-- ------------------------------------------------------------------ -->
	
	var newURL = '/cProfit/officerManagementAccountHolders.asp?id=' + customerID; 

	var entitySelector = document.getElementById('entityType');
	var entityType 	= 	entitySelector.options[entitySelector.selectedIndex].value;
	var selectedTable = htmlElement.parentElement.parentElement.parentElement;
	var selectedRowName	= 	htmlElement.parentElement.getAttribute('data-rowid');
	if (entityType == 'Officer') {
		newURL += '&officer=' + selectedRowName;
	} else {
		newURL += '&branch=' + selectedRowName;
	}

	var selectedColName	= selectedTable.children[0].children[0].children[clickedColumn].children[0].nextSibling.textContent.trim();

	newURL += '&class=' + selectedColName;

	window.location.href = newURL;

	
	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function DrillDownOnService(customerID,htmlElement,clickedRow,clickedColumn) {
//-- ------------------------------------------------------------------ -->
	
	var newURL = '/cProfit/officerManagementAccountHolders.asp?id=' + customerID; 

	var entitySelector = document.getElementById('entityType');
	var entityType 	= 	entitySelector.options[entitySelector.selectedIndex].value;
	
	var selectedTable = htmlElement.closest('table');
	var selectedRow 	= htmlElement.closest('tr');
	
	var selectedRowName	= 	selectedRow.getAttribute('data-rowid');
	
	if (entityType == 'Officer') {
		newURL += '&officer=' + selectedRowName;
	} else {
		newURL += '&branch=' + selectedRowName;
	}

	var selectedColName	= selectedTable.children[0].children[0].children[clickedColumn].innerText.trim();

	newURL += '&service=' + selectedColName;

	window.location.href = newURL;

	
	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function SelectClassificationDrilldown(customerID,className,serviceName,metricName,summaryName) {
//-- ------------------------------------------------------------------ -->
	
// 	var classSelection 		= 	htmlElement.options[htmlElement.selectedIndex].value;
// 	
// 	if (classSelection == 'Select a classification...') {
// 
// 		return false;
// 
// 	} else {
		if (className) {
		
			newURL = '/cProfit/serviceSummary.asp?class=' + className;
			
			if (customerID) {
				newURL = newURL + '&id=' + customerID;
			}
			
			if (serviceName) {
				newURL = newURL + '&service=' + serviceName;
			}
			
			if (metricName) {
				newURL = newURL + '&metric=' + metricName;
			}
			
			if (summaryName) {
				newURL = newURL + '&summary=' + summaryName;
			}
	
			window.location.href 	= newURL;	

	} else {
		
		return false;
		
	}
	
	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function HightLightService () {
//-- ------------------------------------------------------------------ -->
	
	var itemClassList = this.classList; 
	
	if (this.classList) {
		
			if (this.classList.contains('cNoteHighlightedCell')) {
				this.classList.remove('cNoteHighlightedCell');
			} else {
				this.classList.add('cNoteHighlightedCell');
			}
			
// 			this.style.cursor = 'pointer';
			
	}

}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function HighlightGroup () {
//-- ------------------------------------------------------------------ -->
	
	var groupName;
	if ( this.classList.contains('loan') ) {
		groupName = 'loan';
	} else if ( this.classList.contains('deposit') ) {
		groupName = 'deposit';
	} else {
		groupName = 'other';
	}
	
	var currentTD;
	var parentTR = this.parentNode;
	for (var i = 0; i < parentTR.childNodes.length; i++) {

		currentTD = parentTR.childNodes[i];

		if (currentTD.classList) {
			
			if (currentTD.classList.contains(groupName)) {
				
				if (currentTD.classList.contains('cNoteHighlightedCell')) {
					currentTD.classList.remove('cNoteHighlightedCell');
				} else {
					currentTD.classList.add('cNoteHighlightedCell');
				}
				
			}
			
		}

	}
	
}
//-- ------------------------------------------------------------------ -->
	

//-- ------------------------------------------------------------------ -->
function SelectCentileClassificationDrilldown(customerID,className,metricName,centileID) {
//-- ------------------------------------------------------------------ -->
	
	var newURL = "/cProfit/centileServiceSummary.asp?id=" + customerID;
			
	if (className) {
		newURL = newURL + '&class=' + className;
	}
	
	if (metricName) {
		newURL = newURL + '&metric=' + metricName;
	}
	
	if (centileID) {
		newURL = newURL + '&centile=' + centileID;
	}

	window.location.href = newURL;

	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function SelectServiceDrilldown(customerID,className,htmlElement,metricName,summaryName) {
//-- ------------------------------------------------------------------ -->
	
	var serviceSelection 	= 	htmlElement.options[htmlElement.selectedIndex].value;
	
	if (serviceSelection == 'Select a service...') {
		
		return false;
		
	} else {
		
		if (serviceSelection == "Return to services") {
			
			window.location.href = "customerProfit_officerServiceSummary.asp?id=" + customerID + "&metric=" + metricName + "&class=" + className;
			
		} else {

			if (window.location.pathname == "/customerProfit_officerServiceSummary.asp") {

				newURL = "/customerProfit_officerProductSummary.asp?service=" + serviceSelection;
				
			} else {

				newURL = "/customerProfit_officerServiceSummary.asp?service=" + serviceSelection;
			}
			
			if (customerID) {
				newURL = newURL + '&id=' + customerID;
			}
			
			if (className) {
				newURL = newURL + '&class=' + className;
			}
			
			if (metricName) {
				newURL = newURL + '&metric=' + metricName;
			}
			
			if (summaryName) {
				newURL = newURL + '&summary=' + summaryName;
			}
	
			window.location.href = newURL;

		}
			
	}
	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function SelectProductDrilldown(customerID,className,serviceName,metricName,summaryName,htmlElement) {
//-- ------------------------------------------------------------------ -->
	
	var productSelection 	= 	htmlElement.options[htmlElement.selectedIndex].value;
	
	if (productSelection == 'Select a product...') {
		
		return false;
		
	} else {
		
		if (productSelection == "Return to services") {
			
			window.location.href = "customerProfit_officerServiceSummary.asp?id=" + customerID + "&metric=" + metricName + "&class=" + className;
			
		} else {

			newURL = "/customerProfit_officerAccountHolderSummary.asp?product=" + productSelection;
				
			if (customerID) {
				newURL = newURL + '&id=' + customerID;
			}
			
			if (className) {
				newURL = newURL + '&class=' + className;
			}
			
			if (serviceName) {
				newURL = newURL + '&service=' + serviceName;
			}
			
			if (metricName) {
				newURL = newURL + '&metric=' + metricName;
			}
			
			if (summaryName) {
				newURL = newURL + '&summary=' + summaryName;
			}
	
			window.location.href = newURL;

		}
		
	}
	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function SelectMetric(customerID,className,serviceName,htmlElement,summaryName,centileID) {
//-- ------------------------------------------------------------------ -->
	
	var metricSelection 	= 	htmlElement.options[htmlElement.selectedIndex].value;
	
	var newURL	= window.location.pathname + '?metric=' + metricSelection;

	if (customerID) {
		newURL = newURL + '&id=' + customerID;
	}	
	
	if (className) {
		newURL = newURL + '&class=' + className;
	}
	
	if (serviceName) {
		newURL = newURL + '&service=' + serviceName;
	}

	if (summaryName) {
		newURL = newURL + '&summary=' + summaryName;
	}
	
	if (centileID) {
		newURL = newURL + '&centile=' + centileID;
	}

	
	window.location.href 	= newURL;
	
}
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function SelectSummary(customerID,className,serviceName,metricName,htmlElement,centileID) {
//-- ------------------------------------------------------------------ -->
	
	var summarySelection 	= 	htmlElement.options[htmlElement.selectedIndex].value;
	
	var newURL	= window.location.pathname + '?summary=' + summarySelection;

	if (customerID) {
		newURL = newURL + '&id=' + customerID;
	}	
	
	if (className) {
		newURL = newURL + '&class=' + className;
	}
	
	if (serviceName) {
		newURL = newURL + '&service=' + serviceName;
	}
	
	if (metricName) {
		newURL = newURL + '&metric=' + metricName;
	}
	
	if (centileID) {
		newURL = newURL + '&centile=' + centileID;
	}
	
	window.location.href 	= newURL;
	
}
//-- ------------------------------------------------------------------ -->
