// --- config
const blockedTypes = [ 'public', 'bank' ];
const dateFormat   = 'mm/dd/yy';

// --- cache: year -> Set('YYYY-MM-DD')
const holidayCache = new Map();

// --- Shared options (for .datepicker)
const baseOpts = {
	dateFormat: 'mm/dd/yy',
	defaultDate: '+1w',
	changeMonth: true,
	changeYear: true,
	beforeShowDay,
	onChangeMonthYear: function ( year /*, month*/ ) {
		ensureHolidaysForYear( year );
	}
};




	
//------------------------------------------------------------------------------
// Shared beforeShowDay: weekends + holiday types
//------------------------------------------------------------------------------
function beforeShowDay( d ) {
//------------------------------------------------------------------------------

  const dow = d.getDay();
  if ( dow === 0 || dow === 6 ) {
    return [ false, '', 'Weekends are disabled' ];
  }
  const blocked = isHolidayString( d );
  return [ !blocked, blocked ? 'holiday' : '', blocked ? 'Holiday is disabled' : '' ];

}
//------------------------------------------------------------------------------

	
//------------------------------------------------------------------------------
function isHolidayString( d ) {
//------------------------------------------------------------------------------

  const year = d.getFullYear();
  ensureHolidaysForYear( year );
  return holidayCache.get( year ).has( dayjs( d ).format( 'YYYY-MM-DD' ) );

}
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
function ensureHolidaysForYear( year ) {
//------------------------------------------------------------------------------

  if ( holidayCache.has( year ) ) return;

  const set = new Set(
    hd.getHolidays( year )
      .filter( h => blockedTypes.includes( h.type ) )
      .map( h => dayjs( h.date ).format( 'YYYY-MM-DD' ) )
  );

  holidayCache.set( year, set );

}
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Parse an input using jQuery UI's parser to get its year (safe for mm/dd/yy)
//------------------------------------------------------------------------------
function getInputYear( selector ) {
//------------------------------------------------------------------------------

  const val = $( selector ).val();
  if ( !val ) return null;
  try {
    return $.datepicker.parseDate( dateFormat, val ).getFullYear();
  } catch (e) {
    return null;
  }
}
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Prime cache for all relevant years BEFORE initializing pickers
//------------------------------------------------------------------------------
(function primeYears () {
//------------------------------------------------------------------------------

  const years = new Set();

  const nowY   = new Date().getFullYear();
  const startY = getInputYear( '#startDate' );
  const endY   = getInputYear( '#dueDate' );

  years.add( nowY );
  if ( startY ) years.add( startY );
  if ( endY ) years.add( endY );

  years.forEach( y => ensureHolidaysForYear( y ) );

})();
//------------------------------------------------------------------------------




//--------------------------------------------------------------------------------
function getDate( element ) {
//--------------------------------------------------------------------------------

	var date;
	try {
		date = $.datepicker.parseDate( dateFormat, element.value );
	}
	catch ( error ) {
		date = null;
	}
	
	return date;
		
}
//--------------------------------------------------------------------------------



//================================================================================
function handleAjaxError( msg, err ) {
//================================================================================
	
	console.error( msg );
	console.error( err );

	if ( err.status === 401 ) {
		alert( `You session has timed out; you will be redirected to the login page` );
		window.location.href = 'login.asp?msg=Your session has timed out, please log in';
	} else {
		alert( `Unexpected error: ${err.text}. Please contact your system administrator` );
		throw new Error( err );
	}			
	
}
//================================================================================


//================================================================================
function showTransientMessage( msg ) {
//================================================================================

	let notification = document.querySelector('.mdl-js-snackbar');
	
	notification.MaterialSnackbar.showSnackbar({ message: msg });
	

}
//================================================================================


//================================================================================
function getTaskDetails( taskID ) {
//================================================================================
	
	return new Promise( async (resolve, reject) => {

		$.ajax({

			url: `${apiServer}/api/tasks/taskDetail`,
			data: { taskID: taskID },
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		}).done( function( taskDetails ) {
			
			try {	

				$( 'tr.taskName' ).find( 'div.view-mode' ).text( taskDetails.taskName );
				$( 'tr.taskName' ).find( 'div.edit-mode' ).find( 'textarea' ).text( taskDetails.taskName );

				$( 'tr.taskDescription' ).find( 'div.view-mode').text( taskDetails.description );
				$( 'tr.taskDescription' ).find( 'div.edit-mode').find( 'textarea' ).text( taskDetails.description );
				
				$( 'tr.taskSkippedReason' ).find( 'div.view-mode').text( taskDetails.skippedReason );
				$( 'tr.taskSkippedReason' ).find( 'div.edit-mode').find( 'textarea' ).text( taskDetails.skippedReason );
				

				
				const quillContainer = document.getElementById( 'quillAcceptanceCriteria' );
				let quillAcceptanceCriteria = new Quill( quillContainer, {
					modules: {
						toolbar: [
							[{ header: [] }],
							['bold', 'italic', 'underline', 'link'],
							[{ color: [] }, { background: [] }],
							[{ list: 'ordered' }, { list: 'bullet' }],
							['clean']
						]
					},
					theme: 'snow',
				});
				
				$( '#quillAcceptanceCriteria' ).css( 'border', 'none' );
				$( '#quillAcceptanceCriteria' ).prev().hide();
				$( '#quillAcceptanceCriteria' ).next().hide();

				
				try {
					quillAcceptanceCriteria.setContents( JSON.parse( JSON.parse( taskDetails.acceptanceCriteria ) ) );
					$( '#originalAcceptanceCriteria' ).text( taskDetails.acceptanceCriteria );
	
					$( 'div.ql-editor > p' ).css( 'cursor','pointer' );
	
					quillAcceptanceCriteria.on( 'selection-change', function( range, oldRange, source ) {
		
						if ( !range ) return;
		
						if ( source === 'user' ) {
		
							if ( !!range ) {
	
								$( '#quillAcceptanceCriteria' ).css( 'border-left', '1px solid rgb(204, 204, 204)' );
								$( '#quillAcceptanceCriteria' ).css( 'border-bottom', '1px solid rgb(204, 204, 204)' );
								$( '#quillAcceptanceCriteria' ).css( 'border-right', '1px solid rgb(204, 204, 204)' );
								$( '#quillAcceptanceCriteria' ).prev().show();
								$( '#quillAcceptanceCriteria' ).next().show();
								$( 'div.ql-editor > p' ).css( 'cursor','text' );
		
							} else {
		
								$( '#quillAcceptanceCriteria' ).css( 'border', 'none' );
								$( '#quillAcceptanceCriteria' ).prev().hide();
								$( '#quillAcceptanceCriteria' ).prev().hide();
								$( 'div.ql-editor > p' ).css( 'cursor','pointer' );
		
							}
		
						}
		
						return true;
		
					});
				} catch( err ) {
					console.error( 'error creating quill object for acceptance criteria', err );
				}

				

				$( 'tr.taskConditionsOfSatisfaction' ).on( 'click', '.save-button', function() {

					console.log( 'save button clicked' );
					
					const acContents = quillAcceptanceCriteria.getContents();

					saveAcceptanceCriteria( taskID, acContents );
					$( '#originalAcceptanceCriteria' ).text( JSON.stringify( JSON.stringify( acContents ) ) );

					$( 'div.ql-editor > p' ).css( 'cursor','pointer' );
					$( '#quillAcceptanceCriteria' ).css( 'border', 'none' );
					$( '#quillAcceptanceCriteria' ).prev().hide();
					$( '#quillAcceptanceCriteria' ).next().hide();

				});

				$( 'tr.taskConditionsOfSatisfaction' ).on( 'click', '.cancel-button', function() {
					
					quillAcceptanceCriteria.setContents( JSON.parse( JSON.parse( $( '#originalAcceptanceCriteria' ).text() ) ) );
					$( 'div.ql-editor > p' ).css( 'cursor','pointer' );
					$( '#quillAcceptanceCriteria' ).css( 'border', 'none' );
					$( '#quillAcceptanceCriteria' ).prev().hide();
					$( '#quillAcceptanceCriteria' ).next().hide();
					
				});


/*
				$('#startDate')
				  .datepicker('setDate', moment(taskDetails.startDate).toDate())
				  .datepicker( baseOpts )
				  .attr('readonly', true);

				$( '#dueDate' )
				  .datepicker({ dateFormat: 'mm/dd/yy' })
				  .datepicker('setDate', moment(taskDetails.dueDate).toDate())
				  .datepicker( baseOpts )
				  .attr('readonly', true);
*/
				  
				//------------------------------------------------------------------------------
				// Wire up (chain attr so it's set before widget init)
				//------------------------------------------------------------------------------
				const startDate = $( '#startDate' )
					.attr( 'readonly', true )
					.datepicker( baseOpts )
					.datepicker('setDate', moment( taskDetails.startDate ).toDate())
					.on( 'change', async function () {
						await saveTaskDate( 'startDate', taskID, startDate.val() );
						dueDate.datepicker( 'option', 'minDate', getDate( this ) );
						$( '.startDateTip' ).remove();
						$( this ).css( 'color', '' );
					}
				);
				
				const dueDate = $( '#dueDate' )
					.attr( 'readonly', true )
					.datepicker( baseOpts )
					.datepicker('setDate', moment( taskDetails.dueDate ).toDate())
					.on( 'change', async function () {
						await saveTaskDate( 'dueDate', taskID, dueDate.val() );
						startDate.datepicker( 'option', 'maxDate', getDate( this ) );
						$( '.dueDateTip' ).remove();
						$( this ).css( 'color', '' );
					}
				);
				
				dueDate.datepicker( 'option', 'minDate', moment( taskDetails.startDate ).toDate() );
				startDate.datepicker( 'option', 'maxDate', moment( taskDetails.dueDate ).toDate() );
				  


								

				resolve( taskDetails );
				
			} catch( err ) {

				console.error( 'Error getting task details', err );
// 				throw new Error( err );

			}
			


		}).fail( function( err ) {

			reject( err );
			handleAjaxError( 'Error retrieving task details', err );

		});
		
	});

}
//================================================================================


//================================================================================
function getTaskWorkDays( taskID ) {
//================================================================================
	
	return new Promise( async (resolve, reject) => {
		
		$.ajax({

			url: `${apiServer}/api/tasks/workDays`,
			data: { taskID: taskID },
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		}).done( function( taskDetails ) {
			
			try {	

				$( '#newEstimatedWorkDays' ).text( taskDetails.estimatedDays );
				$( '#newActualWorkDays' ).text( taskDetails.actualDays );
				$( '#newWorkDaysAhead' ).text( taskDetails.daysAhead );
				$( '#newWorkDaysBehind' ).text( taskDetails.daysBehind );
				$( '#newWorkDaysAtRisk' ).text( taskDetails.daysAtRisk );
			
				resolve( true );
				
			} catch( err ) {

				console.error( 'Error getting task details' );
				throw new Error( err );

			}
			


		}).fail( function( err ) {

			reject( err );
			handleAjaxError( 'Error retrieving task details', err );

		});
		
	});

}
//================================================================================


//================================================================================
function saveAcceptanceCriteria( taskID, acceptanceCriteria ) {
//================================================================================
	
	$.ajax({

		url: `${apiServer}/api/tasks/acceptanceCriteria`,
		data: { taskID: taskID, acceptanceCriteria: JSON.stringify( acceptanceCriteria ) },
		type: 'PUT',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		showTransientMessage( 'Conditions saved' );
		return true;

	}).fail( function( err ) {

		handleAjaxError( 'Error saving acceptance criteria name', err );

	});
		
}
//================================================================================


//================================================================================
function getCustomerContacts( customerID ) {
//================================================================================
	
	return new Promise( async (resolve, reject) => {
		
		$.ajax({

			url: `${apiServer}/api/customerContacts`,
			data: { customerID: customerID },
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		}).done( function( data ) {
			
			resolve( data );

		}).fail( function( err ) {

			handleAjaxError( 'Error retrieving customer contaxts for taskOwner', err );
			reject( err );

		});
		
	});

}
//================================================================================


//================================================================================
async function getTaskStatuses() {
//================================================================================
	
	try {
	
		return await $.ajax({
			url: `${apiServer}/api/taskStatuses`,
			headers: { 'Authorization': 'Bearer ' + sessionJWT }
		});
		
	} catch {	
		
		handleAjaxError( 'Error retrieving task statuses', err );
		throw new Error( err );

	};
		
}
//================================================================================


//================================================================================
async function getOpenItems( taskID ) {
//================================================================================
	
	try {
	
		return await $.ajax({
			url: `${apiServer}/api/tasks/openItems`,
			data: { taskID: taskID },
			headers: { 'Authorization': 'Bearer ' + sessionJWT }
		});
		
	} catch {	
		
		handleAjaxError( 'Error retrieving task statuses', err );
		throw new Error( err );

	};
		
}
//================================================================================


//================================================================================
function getTaskProjectDetail( projectID ) {
//================================================================================
	
	return new Promise( async (resolve, reject) => {
		
		if ( !!projectID ) {
		
			$.ajax({

				url: `${apiServer}/api/projects/projectDetail`,
				data: { projectID: projectID },
				headers: { 'Authorization': 'Bearer ' + sessionJWT }

			}).done( function( data ) {
				
				resolve( data );
 
			}).fail( function( err ) {

				handleAjaxError( 'Error retrieving project detail for task', err );
				reject( err );

			});

		} else {
			
			
			$( '#projectInfo tr:gt(0)' ).remove();
			$( '#projectInfo' ).append( '<tr><td class="projectStatus" colspan="2">Task is not associated with a project</td></tr>' );
			
			
		}

		
	});

}
//================================================================================


//================================================================================
async function getProjectStatus( projectID ) {
//================================================================================
	
	try {		

		const response = await $.ajax({

			url: `${apiServer}/api/projects/projectStatus`,
			data: { projectID: projectID },
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		});		

		return response;

	} catch( err ) {

		console.error( 'Error retrieving project status', err );
		throw new Error( err );		
		
	}

}
//================================================================================


//================================================================================
function getTaskKeyInitiatives( taskID ) {
//================================================================================
	
	return new Promise( async (resolve, reject) => {
		
		try {
			var table = $( '#taskKeyInitiatives' ).DataTable({

				ajax: {
					url: `${apiServer}/api/keyInitiatives/byTask?taskID=${taskID}`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					dataSrc: ''
				},
				info: false,
				paging: false,
				scrollCollapse: true,
				searching: false,
				columnDefs: [
					{targets: 'name', data: 'name', className: 'name dt-body-left' },
					{targets: 'completeDate', data: 'completeDate', className: 'completeDate dt-body-center' },
				],
			});
			
			resolve( true );
			
		} catch( err ) {
			
			handleAjaxError( 'Error retrieving task key initiatives', err );
			reject( err );
			
		}

	});

}
//================================================================================


//================================================================================
function populateTaskOwner( customerContacts, ownerID ) {
//================================================================================

	try { 

		const $taskOwner = $( '#newTaskOwner' );
		$taskOwner.empty();

		const $defaultOption = $( '<option>', {
			text: 'Make a selection...',
			disabled: 'disabled',
			selected: 'selected',
		});
		$taskOwner.append( $defaultOption );						
		
		for ( contact of customerContacts ) {
			
			const selected = ( contact.id == ownerID ) ? true : false;
			const $option = $( '<option>', {
				value: contact.id,
				text: contact.firstName + ' ' + contact.lastName,
				selected: selected,
			});
			
			$taskOwner.append( $option );						

		}
		
		$taskOwner.selectmenu( "refresh" );
		
	} catch( err ) {

		showTransientMessage( 'Error populating task owner select menu' );
		console.error( err );

	}

}
//================================================================================


//================================================================================
function populateTaskStatus( taskStatuses, taskStatusID, openItems, completionDate ) {
//================================================================================

	try {

		const $taskStatus = $( '#newTaskStatus' );

		const isComplete = String( taskStatusID ) === '2';
		const hasOpenItems = Number( openItems?.openCheckLists || 0 ) + Number( openItems?.openChecklistItems || 0 ) > 0;

		const allowMassComplete = Boolean( taskStatuses?.allowMassComplete );
		const allowUncomplete = Boolean( taskStatuses?.allowUncomplete );

		// Business rules:
		// 1) If there are open items, "Complete" (id=2) is disabled unless allowMassComplete is true.
		const disableCompleteOption = hasOpenItems && !allowMassComplete;

		// 2) If the task is already complete, lock the whole select unless allowUncomplete is true.
		const lockAllStatuses = isComplete && !allowUncomplete;

		$taskStatus.empty();

		$taskStatus.append( $( '<option>', {
			text: 'Make a selection...',
			disabled: true,
			selected: true,
		}) );

		for ( const fubar of taskStatuses.data ) {

			const isSelected = String( fubar.id ) === String( taskStatusID );
			const isCompleteStatus = String( fubar.id ) === '2';

			const disabled =
				lockAllStatuses ||
				( isCompleteStatus && disableCompleteOption );

			$taskStatus.append( $( '<option>', {
				value: fubar.id,
				text: fubar.name,
				selected: isSelected,
				disabled: disabled,
			}) );
		}

		// If we locked everything, ensure user can't interact even if the widget gets cute.
		// Otherwise enable the menu (it may have been disabled previously).
		$taskStatus.selectmenu( lockAllStatuses ? 'disable' : 'enable' );
		$taskStatus.selectmenu( 'refresh' );


		// ---- UI behavior for completion date + date fields ----

		if ( isComplete ) {

			$( '#newCompletionDate' ).closest( 'tr' ).css( 'visibility', 'visible' );
			$( '#newCompletionDate' ).val( dayjs( completionDate ).format( 'MM/DD/YYYY' ) );


			$( '#startDate' )
				.prop( 'disabled', true )
				.parent().attr( 'title', 'Start date cannot be updated for a complete task' );

			$( '#dueDate' )
				.prop( 'disabled', true )
				.parent().attr( 'title', 'Due date cannot be updated for a complete task' );

		} else {

			$( '#newCompletionDate' ).closest( 'tr' )
				.css( 'visibility', 'hidden' )
				.val( null );

			$( '#startDate' )
				.prop( 'disabled', false )
				.parent().attr( 'title', '' )
				.datepicker( 'refresh' );

			$( '#dueDate' )
				.prop( 'disabled', false )
				.parent().attr( 'title', '' )
				.datepicker( 'refresh' );
				
		}

	} catch ( err ) {

		showTransientMessage( 'Error populating task status select menu' );
		console.error( err );
	}
}
//================================================================================




//================================================================================
function populateTaskProjectDetail( taskProjectDetail ) {
//================================================================================

	try { 
		
		$( '#projectName' ).html( `<a href="/taskList.asp?customerID=${customerID}&projectID=${taskProjectDetail.id}">${taskProjectDetail.name}</a>` );
		$( '#projectStartDate' ).text( moment( taskProjectDetail.startDate, 'YYYY-MM-DD' ).format( 'MM/DD/YYYY') );
		$( '#projectEndDate' ).text( moment( taskProjectDetail.endDate, 'YYYY-MM-DD' ).format( 'MM/DD/YYYY' ) );
		
	} catch( err ) {

		showTransientMessage( 'Error populating task/project detail' );
		console.error( err );

	}

}
//================================================================================


//================================================================================
function populateProjectStatus( projectStatus ) {
//================================================================================

	try { 
		
		$( '#projectStatus' ).text( projectStatus.status );
		$( '#projectStatusDate' ).text( projectStatus.statusDate );
		
	} catch( err ) {

		showTransientMessage( 'Error populating project status' );
		console.error( err );

	}

}
//================================================================================


//================================================================================
function getTaskChecklists( taskID ) {
//================================================================================
	
	return new Promise( async (resolve, reject) => {
		
		$.ajax({

			url: `${apiServer}/api/tasks/checklistsByTask?taskID=${taskID}`,
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		}).done( function( data ) {
			
			resolve( data );

		}).fail( function( err ) {

			handleAjaxError( 'Error retrieving checklists', err );
			reject( err );

		});
		
	});

}
//================================================================================


//================================================================================
function saveChecklistName( checklistID, checklistName ) {
//================================================================================
	
	$.ajax({

		url: `${apiServer}/api/tasks/checklistName`,
		data: { id: checklistID, name: checklistName },
		type: 'PUT',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		showTransientMessage( 'Checklist saved' );
		return true;

	}).fail( function( err ) {

		handleAjaxError( 'Error saving checklist name', err );

	});
		
}
//================================================================================


//================================================================================
function saveTaskName( taskID, taskName ) {
//================================================================================
	
	$.ajax({

		url: `${apiServer}/api/tasks/taskName`,
		data: { taskID: taskID, name: taskName },
		type: 'PUT',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		// After saving/updating
		localStorage.setItem( 'projects:dirty', String( Date.now() ) );		showTransientMessage( 'Name saved' );
		return true;

	}).fail( function( err ) {

		handleAjaxError( 'Error saving task name', err );

	});
		
}
//================================================================================


//================================================================================
function saveTaskDescription( taskID, taskDescription ) {
//================================================================================
	
	$.ajax({

		url: `${apiServer}/api/tasks/taskDescription`,
		data: { taskID: taskID, description: taskDescription },
		type: 'PUT',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		showTransientMessage( 'Description saved' );
		return true;

	}).fail( function( err ) {

		handleAjaxError( 'Error saving task description', err );

	});
		
}
//================================================================================


//================================================================================
function saveChecklistItemDescription( checklistItemID, checklistItemDescription ) {
//================================================================================
	
	$.ajax({

		url: `${apiServer}/api/tasks/checklistItemDescription`,
		data: { id: checklistItemID, description: checklistItemDescription },
		type: 'PUT',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		showTransientMessage( 'Checklist item saved' );
		return true;

	}).fail( function( err ) {

		handleAjaxError( 'Error saving checklistItem description', err );

	});
		
}
//================================================================================


//================================================================================
function toggleChecklistItemStatus( domChecklistItemCheckbox ) {
//================================================================================
	
	const id = $( domChecklistItemCheckbox ).closest( 'tr' ).attr( 'id' ).split( '_' )[1];
	const newStatus = ( $( domChecklistItemCheckbox ).text() === 'task_alt' ) ? 0 : 1
	
	$.ajax({

		url: `${apiServer}/api/tasks/checklistItemStatus`,
		data: { id: id, completed: newStatus },
		type: 'PUT',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		let message;
		
		if ( newStatus === 1 ) {
			$( domChecklistItemCheckbox ).text( 'task_alt' );
			message = `Item completed`;
		} else {
			$( domChecklistItemCheckbox ).text( 'radio_button_unchecked' );
			message = `Item un-completed`;
		}

		// After saving/updating
		localStorage.setItem( 'projects:dirty', String( Date.now() ) );			

		showTransientMessage( message );

	}).fail( function( err ) {

		handleAjaxError( 'Error saving checklistItem status', err );

	});
		
}
//================================================================================


//================================================================================
function populateTaskChecklistItem( item, $clTable ) {
//================================================================================
	
	try { 
		
		const itemComplete = ( !!item.completed ) ? 'task_alt' : 'radio_button_unchecked';
		const itemTooltip = ( !!item.completed ) ? 'Click to un-complete this item' : 'Click to complete this item';


		// if <body> exists then use it, else add it and use it...
		let $clBody = $clTable.find ( 'tbody' );
		if ( $clBody.length === 0 ) {
			$clBody = $( '<tbody>' ).appendTo( $clTable );
		}

		
		$clBody.append(
			`<tr id="checklistItem_${item.id}" class="checklistItem">
				<td class="checklistItemCheckbox"><i class="material-symbols-outlined complete" title="${itemTooltip}">${itemComplete}</i></td>
				<td class="checklistItemName editable">
		        <div class="edit-mode cheklist">
		            <textarea style="width: 100%; float: left;">${item.description}</textarea>
		            <button class="save-button edit" style="float: right;"><span class="material-symbols-outlined">check</span></button>
		            <button class="cancel-button edit" style="float: right;"><span class="material-symbols-outlined">close</span></button>
		        </div>
		        <div class="view-mode checklist">
		            ${item.description}
		        </div>
				</td>
				<td class="checklistItemControls">
					<i class="material-symbols-outlined checklistControlIcon deleteChecklistItem" title="Delete this checklist item">delete_outline</i>
				</td>
			</tr>`
		);
			
		$clTable.append( $clBody );

	} catch( err ) {
		
		handleAjaxError( 'error in populateTaskChecklistItem()', err );

	}
}
//================================================================================


//================================================================================
function populateTaskChecklist( checklist ) {
//================================================================================
	
	try {									

		let $clDiv = $( `<div class="checklists">`);
											
		let $clTable = $( `<table class="checklist">` );
		let $clHead = $( `<thead>` );
		let $clBody = $( `<tbody>` );
		
		$clHead.append(	
			`<tr id="checklist_${checklist.id}" class="checklistHeader">
				<th class="checklistName editable" colspan="2">
					<div class="edit-mode">
						<textarea style="width: 98%">${checklist.name}</textarea>
						<button class="save-button">Save</button>
						<button class="cancel-button">Cancel</button>
					</div>
					<div class="view-mode">
						${checklist.name}
					</div>
				</th>
				<th class="checklistControls">
					<i class="material-symbols-outlined addChecklistItem" title="Add an item to this checklist">add_task</i>
					<i class="material-symbols-outlined deleteChecklist" title="Delete checklist and all of its items">delete_outline</i>
				</th>
			</tr>`
		);

		
		$clTable.append( $clHead );
		
		
		if ( !!checklist.items.length ) {
			
			for ( item of checklist.items ) {

				populateTaskChecklistItem( item, $clTable );
				
			}
			
//					$clTable.append( $clBody );

			
		}	// end checklist.items.lengh
			
		$clDiv.append( $clTable );

		$('#taskChecklists').append($clDiv);

	} catch( err ) {
		
		console.error( 'error in populateTaskChecklist()' );
		console.error( err );
		throw new Error( err );
		
	}

}
//================================================================================


//================================================================================
function populateTaskChecklists( taskChecklists ) {
//================================================================================

/* 			return new Promise( async (resolve, reject) => { */

		try { 
			
			if ( !!taskChecklists ) {
			
				for ( checklist of taskChecklists ) {
					
					populateTaskChecklist( checklist );
									
				}
					
			}

		} catch( err ) {

			showTransientMessage( 'Error populating task checklists' );
			console.error( err );
				
		}
	
// 			});

}
//================================================================================


//================================================================================
function makeEditable( domElement ) {
//================================================================================

	const $domElement = $( domElement ).closest( 'tr' );
	$domElement.addClass( 'editing' );
	
	const textareaElement = $domElement.find( 'textarea' ).select();
	const originalText = textareaElement.val();
	
	$domElement.find( '.edit-mode textarea' ).val( originalText );
	
	$domElement.find( '.save-button' ).click( function ( event ) {
		event.preventDefault();
		event.stopPropagation(); // Stop event propagation here
		const newValue = textareaElement.val();
		// Update the view-mode text
		$domElement.find( '.view-mode' ).text( newValue );
		// Remove the editing class to switch back to view mode
		$domElement.removeClass( 'editing' );

		if ( $( this ).closest( 'tr' ).hasClass( 'taskName' ) ) {
			saveTaskName( taskID, newValue );
		} else if ( $( this ).closest( 'tr' ).hasClass( 'taskDescription' ) ) {
			saveTaskDescription( taskID, newValue );
		} else if ( $( this ).closest( 'tr' ).hasClass( 'checklistHeader' ) ) {
			const id = $( this ).closest( 'tr' ).attr( 'id' ).split( '_' )[1];
			saveChecklistName( id, newValue );
		} else {
			const id = $( this ).closest( 'tr' ).attr( 'id' ).split( '_' )[1];
			saveChecklistItemDescription( id, newValue );
		}
						
	});
	
	$domElement.find( '.cancel-button' ).click( function ( event ) {
		event.preventDefault();
		event.stopPropagation(); // Stop event propagation here
		// Restore the original text
		textareaElement.val( originalText );
		// Remove the editing class to switch back to view mode
		$domElement.removeClass( 'editing' );
	});

}
//================================================================================


//================================================================================
function addChecklist( taskID ) {
//================================================================================

	$.ajax({

		url: `${apiServer}/api/tasks/checklist`,
		data: { 
			taskID: taskID, 
			name: $( '#add_checklistName' ).val(), 
		},
		type: 'POST',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		populateTaskChecklist( data );
		// After saving/updating
		localStorage.setItem( 'projects:dirty', String( Date.now() ) );			
		showTransientMessage( 'Checklist added' );

	}).fail( function( err ) {

		handleAjaxError( 'Error saving checklist', err );

	});
}
//================================================================================


//================================================================================
function addChecklistItem( checklistID ) {
//================================================================================

	$.ajax({

		url: `${apiServer}/api/tasks/checklistItem`,
		data: { 
			checklistID: checklistID, 
			description: $( '#add_checklistItemName' ).val(), 
		},
		type: 'POST',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		$clTable = $( `#checklist_${checklistID}` ).closest( 'table' );
		
		populateTaskChecklistItem( data, $clTable );
		// After saving/updating
		localStorage.setItem( 'projects:dirty', String( Date.now() ) );			
		showTransientMessage( 'Checklist item added' );

	}).fail( function( err ) {
		
		handleAjaxError( 'Error saving checklist item', err );

	});
}
//================================================================================


//================================================================================
function deleteChecklist( checklistID ) {
//================================================================================

	$.ajax({

		url: `${apiServer}/api/tasks/checklist`,
		data: { checklistID: checklistID },
		type: 'DELETE',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		$( `#checklist_${checklistID}` ).closest( 'div.checklists' ).remove();
		// After saving/updating
		localStorage.setItem( 'projects:dirty', String( Date.now() ) );			
		showTransientMessage( 'Checklist deleted' );
		 
	}).fail( function( err ) {

		handleAjaxError( 'Error saving checklistItem description', err );

	});
}
//================================================================================


//================================================================================
function deleteChecklistItem( checklistItemID ) {
//================================================================================

	$.ajax({

		url: `${apiServer}/api/tasks/checklistItem`,
		data: { checklistItemID: checklistItemID },
		type: 'DELETE',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		$( `#checklistItem_${checklistItemID}` ).remove();
		// After saving/updating
		localStorage.setItem( 'projects:dirty', String( Date.now() ) );			
		showTransientMessage( 'Checklist item deleted' );
		 
	}).fail( function( err ) {

		handleAjaxError( 'Error deleting checklistItem', err );

	});
}
//================================================================================


//================================================================================
async function updateTaskStatus( taskStatusID ) {
//================================================================================

	return new Promise( async (resolve, reject) => {
	
		$.ajax({
	
			url: `${apiServer}/api/tasks/taskStatus`,
			data: { 
				taskID: taskID,
				taskStatusID: taskStatusID 
			},
			type: 'PUT',
			headers: { 'Authorization': 'Bearer ' + sessionJWT },
			dataType: 'json' 
	
		}).done( function( data ) {
			
			if ( data.allowUncomplete ) {
				$( '#newTaskStatus' ).selectmenu( "enable" );
			} else {
				$( '#newTaskStatus' ).selectmenu( "disable" );
			}
			

			if ( taskStatusID === '1' ) {
				$( '#newCompletionDate' ).closest( 'tr' ).css( 'visibility', 'hidden' );
				$( '#newCompletionDate' ).datepicker( 'setDate', null );
				$( '#newCompletionDate' ).css( 'visibility', 'hidden' );
	
				$("#startDate").prop("disabled", false);
				$("#dueDate").prop("disabled", false);
	
			} else {
				$( '#newCompletionDate' ).datepicker({ dateFormat: 'MM/DD/YYYY' });
				$( '#newCompletionDate' ).datepicker( 'setDate', moment().format('MM/DD/YYYY') );
				$( '#newCompletionDate' ).closest( 'tr' ).css( 'visibility', 'visible' );
				$( '#newCompletionDate' ).css( 'visibility', 'visible' );
				
				$("#startDate").prop("disabled", true);
				$("#dueDate").prop("disabled", true);
								
			}

			// After saving/updating
			localStorage.setItem( 'projects:dirty', String( Date.now() ) );			

			showTransientMessage( 'Task status updated' );

			resolve( true );
			 
		}).fail( function( err ) {
	
			handleAjaxError( 'Error updating task status', err );
			reject( err );
	
		});

	});
	
}
//================================================================================


//================================================================================
function updateTaskOwner( taskOwnerID ) {
//================================================================================

	$.ajax({

		url: `${apiServer}/api/tasks/taskOwner`,
		data: { 
			taskID: taskID,
			taskOwnerID: taskOwnerID 
		},
		type: 'PUT',
		headers: { 'Authorization': 'Bearer ' + sessionJWT }

	}).done( function( data ) {
		
		// After saving/updating
		localStorage.setItem( 'projects:dirty', String( Date.now() ) );			

		showTransientMessage( 'Task owner updated' );

		 
	}).fail( function( err ) {

		handleAjaxError( 'Error updating task ower', err );

	});
	
	
}
//================================================================================


//================================================================================
async function saveTaskDate( targetDate, taskID, taskDate ) {
//================================================================================

	return new Promise( async (resolve, reject) => {

		$.ajax({
	
			url: `${apiServer}/api/tasks/taskDate`,
			data: {
				targetDate: targetDate,
				taskID: parseInt(taskID, 10),
				taskDate: taskDate 
			},
			type: 'PUT',
			headers: { 'Authorization': 'Bearer ' + sessionJWT }
	
		}).done( function( data ) {
			
			
			if (targetDate === 'startDate') {
				$( '#dueDate' ).datepicker( 'option', 'minDate', new Date(taskDate) );
			} else if ( targetDate === 'dueDate' ) {
				$( '#startDate' ).datepicker( 'option', 'maxDate', new Date(taskDate) );
			}
			
			
			showTransientMessage( 'Start date updated' );
			
			
			// After saving/updating
			localStorage.setItem( 'projects:dirty', String( Date.now() ) );			
			
			resolve( true );
			 
		}).fail( function( err ) {
	
			handleAjaxError( 'Error updating start date', err );
			reject( err );
	
		});
		
	});
	
	
}
//================================================================================


//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------

//--------------------------------------------------------------------------------
$( document ).ready( async function() {
//--------------------------------------------------------------------------------

	$( document ).tooltip();


	$( "#newCompletionDate" ).datepicker();

		
	$( '#newTaskOwner' ).selectmenu({
		change: function( event, ui ) {
			updateTaskOwner( ui.item.value );
		}
	});


	$( '#newTaskStatus' ).selectmenu({
				
		change: async function( event, ui ) {
	
			const taskStatusID = ui.item.value; 

			await updateTaskStatus( taskStatusID );		
			await getTaskWorkDays( taskID );

			const taskStatuses = await getTaskStatuses();
			const openItems = await getOpenItems( taskID );
			
			
			await populateTaskStatus( taskStatuses, taskStatusID, openItems, taskDetails.completionDate );
			
		}
	});

	let checklistDialog = $( '#addChecklist' ).dialog({
		autoOpen: false,
		modal: true,
		buttons: {
			Save: function() {
				addChecklist( taskID );
				checklistDialog.dialog( 'close' );
			},
			Cancel: function() {
				checklistDialog.dialog( 'close' );
			},
		},
		close: function() {
			$( '#add_checklistName' ).val( '' );
		}
	});


	let checklistItemDialog = $( '#addChecklistItem' ).dialog({
		autoOpen: false,
		modal: true,
		buttons: {
			Save: function() {
				const checklistID = $( this ).data( 'checklistID' );
				addChecklistItem( checklistID );
				checklistItemDialog.dialog( 'close' );
			},
			Cancel: function() {
				checklistItemDialog.dialog( 'close' );
			},
		},
		close: function() {
			$( '#add_checklistItemName' ).val( '' );
		}
	});


	let deleteChecklistDialog = $( '#deleteChecklist' ).dialog({
		autoOpen: false,
		resizable: false,
		height: "auto",
		width: 400,
		modal: true,
		buttons: {
			"Delete checklist": function() {
				const checklistID = $( this ).data( 'checklistID' );
				deleteChecklist( checklistID );
				$( this ).dialog( "close" );
			},
			Cancel: function() {
				$( this ).dialog( "close" );
			},
		},
	});

	
	let deleteChecklistItemDialog = $( '#deleteChecklistItem' ).dialog({
		autoOpen: false,
		resizable: false,
		height: "auto",
		width: 400,
		modal: true,
		buttons: {
			"Delete item": function() {
				const checklistItemID = $( this ).data( 'checklistItemID' );
				deleteChecklistItem( checklistItemID );
				$( this ).dialog( "close" );
			},
			Cancel: function() {
				$( this ).dialog( "close" );
			},
		},
	});

	
	$( '#newTaskDescription' ).on( 'input', function() {

		$( this ).css( 'height', 'auto' );
		$( this ).css( 'height', this.scrollHeight+'px' );

	});
	

	try {

		const [ taskDetails, taskWorkDays, taskStatuses, openItems, customerContacts, taskKeyInitiatives, taskChecklists ] = await Promise.all([
			getTaskDetails( taskID ),
			getTaskWorkDays( taskID ),
			getTaskStatuses(),
			getOpenItems( taskID ),
			getCustomerContacts( customerID ),
			getTaskKeyInitiatives( taskID ),
			getTaskChecklists( taskID ),
		]);
		
		populateTaskOwner( customerContacts, taskDetails.ownerID );
		populateTaskStatus( taskStatuses, taskDetails.taskStatusID, openItems, taskDetails.completionDate );
		populateTaskChecklists( taskChecklists );

		$( '#taskChecklists' )
			.on( 'mouseover', '.checklistItem', function( event) {
				event.preventDefault();
				$(this).css( 'background-color', 'lightgrey' );
				$(this).find( '.checklistControlIcon' ).css({
					'visibility': 'visible',
					'opacity': '1'
				});
			})
			.on( 'mouseout', '.checklistItem', function( event) {
				event.preventDefault();
				$(this).css( 'background-color', 'white' );
				$(this).find( '.checklistControlIcon' ).css({
					'visibility': 'hidden',
					'opacity': '0'
				});
			})
			.on( 'click', '.editable', function( event ) {
				event.preventDefault();
				makeEditable( this );
			})
			.on( 'click', 'td.checklistItemCheckbox i', function( event ) {
				event.preventDefault();
				toggleChecklistItemStatus( this );
			})
			.on( 'click', '#addChecklist', function( event ) {
				event.preventDefault();
				event.stopPropagation();
	
				checklistDialog.dialog( 'option', 'position', {
					my: 'left top',
					at: 'left bottom',
					of: this
				}).dialog( 'open' );
			})
			.on( 'click', 'i.deleteChecklist', function( event ) {

				event.preventDefault();
				event.stopPropagation();
				const checklistID = $( this ).closest( 'tr' ).attr( 'id' ).split( '_' )[1];
				$( '#deleteChecklist' ).dialog( 'option', 'position', {
					my: 'left top',
					at: 'left bottom',
					of: this
				})
				.data( 'checklistID', checklistID )
				.dialog( 'open' );
				
			})
			.on( 'click', 'i.addChecklistItem', function( event ) {
				
				event.preventDefault();
				event.stopPropagation();
	
				const checklistID = $( this ).closest( 'tr' ).attr( 'id' ).split( '_' )[1];
	
				checklistItemDialog
					.dialog( 'option', 'position', {
						my: 'left top',
						at: 'left bottom',
						of: this
					})
					.data( 'checklistID', checklistID ).dialog( 'open' );
	
			})
			.on( 'click', 'i.deleteChecklistItem', function( event ) {

				event.preventDefault();
				event.stopPropagation();
				
				const checklistID = $( this ).closest( 'tr' ).attr( 'id' ).split( '_' )[1];
	
				$( '#deleteChecklistItem' ).dialog( 'option', 'position', {
					my: 'left top',
					at: 'left bottom',
					of: this
				})
				.data( 'checklistItemID', checklistID )
				.dialog( 'open' );
				
			});

		
		$( '#taskOverview' ).on( 'click', '.editable', function( event ) {
			event.preventDefault();
			makeEditable( this );
		});

		
		const taskProjectDetail = await getTaskProjectDetail( taskDetails.projectID );
		populateTaskProjectDetail( taskProjectDetail );

		const projectStatus = await getProjectStatus( taskDetails.projectID );
		
		if ( !!projectStatus ) {
			populateProjectStatus( projectStatus );
		}


	} catch (error) {

		console.error(error);

	}
	
	

	


});
