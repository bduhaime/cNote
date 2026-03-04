//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->
//--                                                                    -->
//--        /cProfit/includes/accountHolderPopup.js                     -->
//--                                                                    -->
//-- ------------------------------------------------------------------ -->


//-- ------------------------------------------------------------------ -->
function AccountHolderFlagsButton_onClick (htmlElement,event) {
//-- ------------------------------------------------------------------ -->
					
					
					
}
					
//-- ------------------------------------------------------------------ -->
function AddendaButton_onClick (htmlElement,event) {
//-- ------------------------------------------------------------------ -->
					
					
	// find existing context menu; if found, remove it!
	var existingMenu = document.querySelector('.contextMenu');
	if (existingMenu) {
		existingMenu.parentNode.removeChild(existingMenu);
	}
	

	// clone the template menu....
	var menuTemplate = document.getElementById('addendaContextMenu');
	var menu = menuTemplate.cloneNode(true);
	menu.classList.add('contextMenu');








	// add eventListeners for cancel/save comment butons...
	var newComment = menu.querySelector('#newComment');
	if (newComment) {
		
		newComment.addEventListener('focus', function() {
			const parentRow = newComment.closest('tr');
			parentRow.querySelector("button.cancel").disabled = false;
		});

		newComment.addEventListener('input', function() {
			const parentRow = newComment.closest('tr');
			parentRow.querySelector("button.save").disabled = false;
		});
		
	}

	const newCommentCancel = menu.querySelector('button.cancel');
	if (newCommentCancel) {
		newCommentCancel.addEventListener('click', function() {
			const newComment = menu.querySelector('#newComment');
			const parentRow = newComment.closest('tr');
			newComment.value = '';
			parentRow.querySelector("button.cancel").disabled = true;
			parentRow.querySelector("button.save").disabled = true;
		});
	}

	const newCommentSave = menu.querySelector('button.save');
	if (newCommentSave) {
		newCommentSave.addEventListener('click', function() {

			const accountHolderNumber = this.closest('div.cNoteAddendaContextMenu').id;
			const newCommentTR = this.closest('tr');
			const newCommentTA = newCommentTR.querySelector('textarea');
			const newCommentContent = newCommentTA.value;

			SaveNewAccountHolderComment(accountHolderNumber,<% =customerID %>, newCommentContent, table);
			
		});
	}

	const closeIcon = '<i class="material-icons close" style="float: right; cursor: pointer;">close</i>';
	const namePlaceholderIcon = '<i class="material-icons" style="float: left;">portrait</i>';

	// populate the customer name...
	
	if ( htmlElement.closest('tr') ) {
		var accountHolderElem = htmlElement.closest('tr');
		var accountHolderNameElem = accountHolderElem.querySelector('.accountHolderName');
	} else {
		var accountHolderElem = htmlElement.closest('div');
		var accountHolderNameElem = accountHolderElem.querySelector('.accountHolderName');
	}
	
	
	if (accountHolderNameElem.classList.contains('is-upgraded')) {
		menu.querySelector('.accountHolderName').innerHTML = '<b>' + accountHolderNameElem.textContent + '</b>' + closeIcon;
	} else {
		menu.querySelector('.accountHolderName').innerHTML = namePlaceholderIcon + closeIcon;
		menu.querySelector('.accountHolderName').style.height = '20px';
	}

	var menuCloseIcon = menu.querySelector('i.close');
	if (menuCloseIcon) {
		menuCloseIcon.addEventListener('click', function() {
			menu.parentNode.removeChild(menu);
		});
	}


	// fetch flags and first comment...
	EditAccountHolderAddenda(accountHolderElem,menu,table);

	// apend the menu to the MDL "page-content" <div>...		
	document.querySelector('.page-content').appendChild(menu);
	
	
	
	var newTop = event.screenY;
// 			if (newTop < 850) {
// 				newTop = newTop + 115;
// 			} else {
// 				newTop = newTop - 200;
// 			}
	var newLeft = event.screenX - 40;
	
	menu.classList.add('cNoteShowAddendaContextMenu');
	menu.style.top = (newTop - 200) + 'px';
	menu.style.left = newLeft + 'px';
	menu.style.zIndex = 100;

	menu.style.display = 'block';

	
		
	

}


	
