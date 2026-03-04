
let timer;


window.onbeforeunload = function() {
	document.querySelector('.mdl-spinner').classList.add('is-active');
}

google.charts.load('current', {packages: ['corechart', 'timeline', 'controls']});
//google.charts.setOnLoadCallback( drawCharts() );


//====================================================================================
function updateUserSelectionList( startDate, endDate ) {
//====================================================================================

	return new Promise((resolve, reject) => {

		// snapshot unchecked before any clearing
		const unchecked = new Set(
			$('#userSelectionList input.user').not(':checked')
			.map((_, el) => el.id).get()
		);
		
		$.ajax({

			beforeSend: function () {
				$('.progressbar').progressbar({ value: false });
				// DO NOT nuke the selection list yet
				$('.widget').not('#userSelectionList').html('');
			},
			url: `${apiServer}/api/sysop/userSelectionList`,
			data: { startDate, endDate },
			headers: { Authorization: 'Bearer ' + sessionJWT }

		}).done(function (data) {

			let html = '';
			for (const user of data) {
				const id = `user-${user.id}`;
				const checked = unchecked.has(id) ? '' : 'checked'; // preserve unchecks
				html += `
					<div class="user">
					<label for="${id}" title="Last activity was at ${user.activityDateTime}">
					${user.userName}&nbsp;(${user.lastActivity})
					</label>
					<input class="user" type="checkbox" id="${id}" ${checked}>
					</div>
				`;
			}
			$('#userSelectionList_progressbar').progressbar('destroy');
			$('#userSelectionList').html(html);
			$('input.user').checkboxradio();
			resolve();

		}).fail(function (req, status, err) {

			$('#userSelectionList_progressbar').progressbar('destroy');
			console.error('Something went wrong in updateUserSelectionList()');
			reject(err);

		});

	});

}
//====================================================================================


//====================================================================================
function getSelectedUsers() {
//====================================================================================

	return new Promise( (resolve, reject) => {

		let users = []

		$( 'input.user' ).each( function() {

			if ( $( this ).is( ':checked' ) ) {

				elemID = $(this).attr('id');
				userID = elemID.substring( elemID.indexOf('-')+1, elemID.length );

				users.push(
					parseInt( userID )
				);

			}

		});

		return resolve( users ) ;

	});

}
//====================================================================================


//====================================================================================
function chartActivityByTimeOfDay( startDate, endDate, users ) {
//====================================================================================

	return new Promise( (resolve, reject) => {

		$.ajax({
			beforeSend: function() {
				$( '#timeOfDay_progressbar' ).progressbar({ value: false });
				$( '#timeOfDay' ).html( '' );
			},
			dataType: "json",
			url: `${apiServer}/api/sysop/activityByTimeOfDay`,
				data: {
					users: users,
					startDate: startDate,
					endDate: endDate
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
		}).done( function( data ) {

			let chart = new google.visualization.ColumnChart(document.getElementById( 'timeOfDay' ));
			let dataTable = new google.visualization.DataTable( data );
			chart.draw( dataTable, {
		      hAxis: {
			      ticks: [
			      	{v: 0, 	f: '12a'},
			      	{v: 4, 	f: '4a'},
			      	{v: 8, 	f: '8a'},
			      	{v: 12, 	f: '12p'},
			      	{v: 16, 	f: '4p'},
			      	{v: 20, 	f: '8p'},
			      	{v: 24, 	f: '12a'}
			      ],
		      },
	         height: '200',
		      legend: { position: 'none' },
		      series: { 0: {color: 'orange'} },
	         title: 'Page Hits By Time Of Day',
	         vAxis: { title: 'Page Hits' }
			});
			$( '#timeOfDay_progressbar' ).progressbar('destroy');
			resolve();

		}).fail( function( req, status, err ) {

			$( '#timeOfDay_progressbar' ).progressbar('destroy');
			console.error( `Something went wrong (${status}) in chartActivityByTimeOfDay(), please contact your system administrator.` );
			throw new Error( err );

		});


	});

}
//====================================================================================


//====================================================================================
function chartActivityByDayOfWeek( startDate, endDate, users ) {
//====================================================================================

	return new Promise( (resolve, reject) => {

		$.ajax({

			beforeSend: function() {
				$( '#dayOfWeek_progressbar' ).progressbar({ value: false });
				$( '#dayOfWeek' ).html( '' );

			},
			dataType: "json",
			url: `${apiServer}/api/sysop/activityByDayOfWeek`,
			data: {
				users: users,
				startDate: startDate,
				endDate: endDate
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT },

		}).done( function( data ) {

			let chart = new google.visualization.ColumnChart(document.getElementById( 'dayOfWeek' ));
			let dataTable = new google.visualization.DataTable( data );
			chart.draw( dataTable, {
	         height: '200',
		      legend: { position: 'none' },
		      hAxis: {
			      ticks: [
			      	{v: 1, f: 'Sun'},
			      	{v: 2, f: 'Mon'},
			      	{v: 3, f: 'Tue'},
			      	{v: 4, f: 'Wed'},
			      	{v: 5, f: 'Thu'},
			      	{v: 6, f: 'Fri'},
			      	{v: 7, f: 'Sat'}
			      ]
			   },
		      series: { 0: {color: 'blue'} },
	         title: 'Page Hits By Day Of Week',
	         vAxis: { title: 'Page Hits' },
			});
			$( '#dayOfWeek_progressbar' ).progressbar('destroy');
			resolve();

		}).fail( function( req, status, err ) {

			console.error( `Something went wrong (${status}) in chartActivityByDayOfWeek(), please contact your system administrator.` );
			throw new Error( err );

		});


	});

}
//====================================================================================


//====================================================================================
function chartActivityByDate( startDate, endDate, users ) {
//====================================================================================

	return new Promise( (resolve, reject) => {

		$.ajax({

			beforeSend: function() {
				$( '#date_progressbar' ).progressbar({ value: false });
				$( '#date' ).html( '' );
			},
			dataType: "json",
			url: `${apiServer}/api/sysop/activityByDate`,
			data: {
				users: users,
				startDate: startDate,
				endDate: endDate
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT },

		}).done( function( data ) {

			let chart = new google.visualization.ColumnChart(document.getElementById( 'date' ));
			let dataTable = new google.visualization.DataTable( data );
			chart.draw( dataTable, {
	         height: 	'200',
		      legend: 	{ position: 'none' },
		      hAxis: 	{ format: 'MMM d', slantedText: true,minorGridlines: { count: 0 } },
		      series: 	{ 0: {color: 'red'} },
	         title: 	'Page Hits By Date',
	         vAxis: 	{ title: 'Page Hits' },
			});
			$( '#date_progressbar' ).progressbar('destroy');
			resolve();

		}).fail( function( req, status, err ) {

			console.error( `Something went wrong (${status}) in chartActivityByDate(), please contact your system administrator.` );
			throw new Error( err );

		});

	});


}
//====================================================================================


//====================================================================================
function chartActivityByUser( startDate, endDate, users ) {
//====================================================================================

	return new Promise( (resolve, reject) => {

		$.ajax({

			beforeSend: function() {
				$( '#user_progressbar' ).progressbar({ value: false });
				$( '#user' ).html( '' );
			},
			dataType: "json",
			url: `${apiServer}/api/sysop/activityByUser`,
			data: {
				users: users,
				startDate: startDate,
				endDate: endDate
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		}).done( function( data ) {

			let chart = new google.visualization.ColumnChart(document.getElementById( 'user' ));
			let dataTable = new google.visualization.DataTable( data );
			chart.draw( dataTable, {
		      hAxis: 	{ slantedText: true },
	         height: 	'200',
		      legend: 	{ position: 'none' },
		      series: 	{ 0: {color: 'purple'} },
	         title: 	'Page Hits By User',
	         vAxis: 	{ title: 'Page Hits' },
			});
			$( '#user_progressbar' ).progressbar('destroy');
			resolve();

		}).fail( function( req, status, err ) {

			console.error( `Something went wrong (${status}) in chartActivityByUser(), please contact your system administrator.` );
			throw new Error( err );

		});


	});

}
//====================================================================================


//====================================================================================
function chartPageHits( startDate, endDate, users, interstitials ) {
//====================================================================================

	return new Promise( (resolve, reject) => {
		
		$.ajax({

			beforeSend: function() {
				$( '#pageHits_progressbar' ).progressbar({ value: false });
				$( '#pageHits' ).html( '' );
			},
			dataType: "json",
			url: `${apiServer}/api/sysop/pageHits`,
			data: {
				users: users,
				startDate: startDate,
				endDate: endDate,
				interstitials: interstitials
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		}).done( function( data ) {

			let chart = new google.visualization.PieChart(document.getElementById( 'pageHits' ));
			let dataTable = new google.visualization.DataTable( data );
			chart.draw(dataTable, {
				height: 	300,
				title: 	'Page Hits',
		      legend: 	{ position: 'none' },
				slices: 	{ 0: { offset: 0.1 } },
				sliceVisibilityThreshold: .01,
			});
			$( '#pageHits_progressbar' ).progressbar('destroy');
			$( 'span.interstitials' ).show();
			resolve();

		}).fail( function( req, status, err ) {

			console.error( `Something went wrong (${status}) in chartPageHits(), please contact your system administrator.` );
			throw new Error( err );

		});



	});

}
//====================================================================================


//====================================================================================
function chartNodeAPIHits( startDate, endDate, users ) {
//====================================================================================

	return new Promise( (resolve, reject) => {

		$.ajax({

			beforeSend: function() {
				$( '#nodeEndPointHits_progressbar' ).progressbar({ value: false });
				$( '#nodeEndPointHits' ).html( '' );
			},
			dataType: "json",
			url: `${apiServer}/api/sysop/nodeEndPointHits`,
			data: {
				users: users,
				startDate: startDate,
				endDate: endDate
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		}).done( function( data ) {

			let chart = new google.visualization.PieChart(document.getElementById( 'nodeEndPointHits' ));
			let dataTable = new google.visualization.DataTable( data );
			chart.draw(dataTable, {
				height:	 300,
				title: 	'Node.js Endpoint Hits',
		      legend: 	{ position: 'none' },
				slices: 	{ 0: { offset: 0.1 } },
				sliceVisibilityThreshold: .01,
			});
			$( '#nodeEndPointHits_progressbar' ).progressbar('destroy');
			resolve();

		}).fail( function( req, status, err ) {

			console.error( `Something went wrong (${status}) in chartNodeAPIHits(), please contact your system administrator.` );
			throw new Error( err );

		});


	});

}
//====================================================================================


//====================================================================================
function chartASPAPIHits( startDate, endDate, users ) {
//====================================================================================

	return new Promise( (resolve, reject) => {

		$.ajax({

			beforeSend: function() {
				$( '#aspEndPointHits_progressbar' ).progressbar({ value: false });
				$( '#aspEndPointHits' ).html( '' );
			},
			dataType: "json",
			url: `${apiServer}/api/sysop/aspEndPointHits`,
			data: {
				users: users,
				startDate: startDate,
				endDate: endDate
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		}).done( function( data ) {

			let chart = new google.visualization.PieChart(document.getElementById( 'aspEndPointHits' ));
			let dataTable = new google.visualization.DataTable( data );
			chart.draw(dataTable, {
				height: 	300,
				title: 	'Classic ASP Endpoint Hits',
		      legend: 	{ position: 'none' },
				slices: 	{ 0: { offset: 0.1 } },
				sliceVisibilityThreshold: .005,
			});
			$( '#aspEndPointHits_progressbar' ).progressbar('destroy');
			resolve();

		}).fail( function( req, status, err ) {

			console.error( `Something went wrong (${status}) in chartASPAPIHits(), please contact your system administrator.` );
			throw new Error( err );

		});


	});

}
//====================================================================================


//====================================================================================
function chartASPvsNodeAPIHits( startDate, endDate, users ) {
//====================================================================================

	return new Promise( (resolve, reject) => {

		$.ajax({

			beforeSend: function() {
				$( '#aspVsNodeHits_progressbar' ).progressbar({ value: false });
				$( '#aspVsNodeHits' ).html( '' );
			},
			dataType: "json",
			url: `${apiServer}/api/sysop/aspVsNodeHits`,
			data: {
				users: users,
				startDate: startDate,
				endDate: endDate
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		}).done( function( data ) {

			let chart = new google.visualization.PieChart(document.getElementById( 'aspVsNodeHits' ));
			let dataTable = new google.visualization.DataTable( data );
			chart.draw(dataTable, {
				height: 	300,
				title: 	'Classic ASP vs. Node.js Endpoint Hits',
		      legend: 	{ position: 'none' },
				slices: 	{ 0: { offset: 0.1 } },
			});
			$( '#aspVsNodeHits_progressbar' ).progressbar('destroy');
			resolve();

		}).fail( function( req, status, err ) {

			console.error( `Something went wrong (${status}) in chartASPvNodeAPIHits(), please contact your system administrator.` );
			throw new Error( err );

		});



	});

}
//====================================================================================


//====================================================================================
function chartDashboards( startDate, endDate, users, dashboard ) {
//====================================================================================

	return new Promise( (resolve, reject) => {

		const dashboards = {
			exec: {
				scriptName: '/executiveDashboard.asp',
				title: 'Executive Dashboard Usage By User',
				color: 'red'
			},
			customers: {
				scriptName: '/customerMetricsDashboard.asp',
				title: 'Customer Metrics Usage By User',
				color: 'orange'
			},
			calls: {
				scriptName: '/customerCallsDashboard.asp',
				title: 'Customer Call Metrics Usage By User',
				color: 'purple'
			},
			coaches: {
				scriptName: '/coachMetricsDashboard.asp',
				title: 'Coach Metrics Usage By User',
				color: 'blue'
			},
		}

		let scriptName, title, color
		if ( dashboard in dashboards ) {

			container = dashboards[dashboard].container
			scriptName = dashboards[dashboard].scriptName
			title = dashboards[dashboard].title
			color = dashboards[dashboard].color

		} else {
			console.error( 'invalid dashboard value: ' + dashboard )
			reject( 'invalid dashboard parameter' )
			return
		}

		const containerElement = document.getElementById( dashboard );
		if (!containerElement) {
			console.error(`Container element ${dashboard} not found.`);
			reject(`Container element ${dashboard} not found.`);
			return; // Return here to avoid continuing the function if the container element is not found.
		}


		$.ajax({
			beforeSend: function() {
				$( `#${dashboard}_progressbar` ).progressbar({ value: false });
				$( `#${dashboard}` ).html( '' );
			},
			dataType: "json",
			url: `${apiServer}/api/sysop/dashboardUsage`,
				data: {
					users: users,
					startDate: startDate,
					endDate: endDate,
					dashboardScript: scriptName
				},
				headers: { 'Authorization': 'Bearer ' + sessionJWT },
		}).done( function( data ) {

			let chart = new google.visualization.ColumnChart( containerElement );
			let dataTable = new google.visualization.DataTable( data );
			chart.draw( dataTable, {
		      hAxis: { slantedText: true },
	         height: '200',
		      legend: { position: 'none' },
		      series: { 0: {color: color } },
	         title: title,
		      tooltip: { isHtml: true },
	         vAxis: { title: 'Page Hits' }
			});
			$( `#${dashboard}_progressbar` ).progressbar('destroy');
			resolve();

		}).fail( function( req, status, err ) {

			$( `#${dashboard}_progressbar` ).progressbar('destroy');
			console.error( `Something went wrong (${err}) in chartExecDashboard(), please contact your system administrator.` );
			throw new Error( err );

		});


	});

}
//====================================================================================


//====================================================================================
function chartSessions( startDate, endDate ) {
//====================================================================================

	return new Promise( (resolve, reject) => {

		$.ajax({

			beforeSend: function() {
				$( '#sessions_progressbar' ).progressbar({ value: false });
				$( '#sessions' ).html( '' );
			},
			dataType: "json",
			url: `${apiServer}/api/sysop/sessionUsage`,
			data: {
				startDate: startDate,
				endDate: endDate
			},
			headers: { 'Authorization': 'Bearer ' + sessionJWT }

		}).done( function( data ) {

			let chart = new google.visualization.ColumnChart(document.getElementById( 'sessions' ));
			let dataTable = new google.visualization.DataTable( data );
			chart.draw(dataTable, {
				vAxes: {
					0: { title: 'Count of Sessions', format: '#,###', titleTextStyle: { color: 'blue' } },
					1: { side: 'right', title: 'Average Session Length (seconds)', format: '#,###,###', titleTextStyle: { color: 'crimson' } }
				},
		      hAxis: { slantedText: true },
				height: 	300,
		      legend: 	{ position: 'none' },
		      series: {
					0: { targetAxisIndex: 0, color: 'blue' },
					1: { targetAxisIndex: 1, color: 'crimson' }
				},
	         title: 'Sessions by User',
		      tooltip: { isHtml: true },
			});
			$( '#sessions_progressbar' ).progressbar('destroy');
			resolve();

		}).fail( function( req, status, err ) {

			console.error( `Something went wrong (${status}) in chartSessions(), please contact your system administrator.` );
			throw new Error( err );

		});



	});

}
//====================================================================================


//====================================================================================
function getDates( dateRange ) {
//====================================================================================

	let startDate, endDate;

	switch ( dateRange ) {
		case 'yesterday':
			startDate = dayjs().subtract( 1, 'day' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().subtract( 1, 'day' ).format( 'MM/DD/YYYY' );
			break;

		case 'this week':
			startDate = dayjs().startOf( 'week' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().format( 'MM/DD/YYYY' );
			break;

		case 'last week':
			startDate = dayjs().subtract( 1, 'week' ).startOf( 'week' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().subtract( 1, 'week' ).endOf( 'week' ).format( 'MM/DD/YYYY' );
			break;

		case 'this month':
			startDate = dayjs().startOf( 'month' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().format( 'MM/DD/YYYY' );
			break;

		case 'last month':
			startDate = dayjs().subtract( 1, 'month' ).startOf( 'month' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().subtract( 1, 'month' ).endOf( 'month' ).format( 'MM/DD/YYYY' );
			break;

		case 'this quarter':
			startDate = dayjs().startOf( 'quarter' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().format( 'MM/DD/YYYY' );
			break;

		case 'last thirty days':
			startDate = dayjs().subtract( 29, 'day' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().format( 'MM/DD/YYYY' );
			break;

		case 'last ninety days':
			startDate = dayjs().subtract( 89, 'day' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().format( 'MM/DD/YYYY' );
			break;


		case 'last quarter':
			startDate = dayjs().subtract( 1, 'quarter' ).startOf( 'quarter' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().subtract( 1, 'quarter' ).endOf( 'quarter' ).format( 'MM/DD/YYYY' );
			break;

		case 'this year':
			startDate = dayjs().startOf( 'year' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().format( 'MM/DD/YYYY' );
			break;

		case 'last year':
			startDate = dayjs().subtract( 1, 'year' ).startOf( 'year' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().subtract( 1, 'year' ).endOf( 'year' ).format( 'MM/DD/YYYY' );
			break;

		case 'custom':
			startDate = dayjs( $( '#startDate' ).val(), 'MM/DD/YYYY' ).format( 'MM/DD/YYYY' );
			endDate = dayjs( $( '#endDate' ).val(), 'MM/DD/YYYY' ).format( 'MM/DD/YYYY' );
			break;

		case 'today':
			startDate = dayjs().format( 'MM/DD/YYYY' );
			endDate = dayjs().format( 'MM/DD/YYYY' );
			break;

		case 'last seven days':
		default:
			startDate = dayjs().subtract( 6, 'day' ).format( 'MM/DD/YYYY' );
			endDate = dayjs().format( 'MM/DD/YYYY' );


	}

	$( "#startDate" ).datepicker( 'option', 'maxDate', endDate );
	$( "#endDate" ).datepicker( 'option', 'minDate', startDate );

	return { startDate, endDate }

}
//====================================================================================


//====================================================================================
function drawCharts( dateRange ) {
//====================================================================================

	const dates = getDates( dateRange );

	$( '#startDate' ).val( dates.startDate );
	$( '#endDate' ).val( dates.endDate );


	let interstitials;
	if ( $( '#interstitials' ).parent().hasClass( 'is-checked' ) ) {
		interstitials = true;
	} else {
		interstitials = false;
	}



	updateUserSelectionList( dates.startDate, dates.endDate )
	.then( () => getSelectedUsers() )
	.then( users => {

		chartActivityByTimeOfDay( dates.startDate, dates.endDate, users);
		chartActivityByDayOfWeek( dates.startDate, dates.endDate, users );
		chartActivityByDate( dates.startDate, dates.endDate, users );
		chartActivityByUser( dates.startDate, dates.endDate, users );
		chartPageHits( dates.startDate, dates.endDate, users, interstitials );
		chartNodeAPIHits( dates.startDate, dates.endDate, users );
		chartASPAPIHits( dates.startDate, dates.endDate, users );
		chartASPvsNodeAPIHits( dates.startDate, dates.endDate, users );
		chartDashboards( dates.startDate, dates.endDate, users, 'exec' );
		chartDashboards( dates.startDate, dates.endDate, users, 'customers' );
		chartDashboards( dates.startDate, dates.endDate, users, 'calls' );
		chartDashboards( dates.startDate, dates.endDate, users, 'coaches' );
		chartSessions( dates.startDate, dates.endDate );

	}).catch( err => {
		alert( 'something bad happened!' );
		console.error( err );
	});
	

		const $multiDomains = $('#customersMultipleValidDomains');
		
		if ( $.fn.dataTable.isDataTable( $multiDomains ) ) {
			$multiDomains.DataTable().ajax.reload();
		} else {
			$multiDomains.DataTable({
				ajax: {
					url: `${apiServer}/api/customers/customersMultipleValidDomains`,
					headers: { 'Authorization': 'Bearer ' + sessionJWT },
					dataSrc: ''
				},
				columnDefs: [
					{ targets: 'name', data: 'name', className: 'dt-body-left dt-head-left' },
					{ targets: 'validDomains', data: 'validDomains', className: 'dt-body-left dt-head-left' },
				],
				autoWidth: false,
				responsive: true,
				dom: 'rt'
			});
		}
		
	

		const $tbl = $('#customersRecentlyUpdatedDomains');
		
		if ($.fn.dataTable.isDataTable($tbl)) {
		  $tbl.DataTable().ajax.reload();
		} else {
			$tbl.DataTable({
				ajax: {
					url: `${apiServer}/api/customers/customersRecentlyUpdatedDomains`,
					headers: { Authorization: 'Bearer ' + sessionJWT },
					dataSrc: '' // your array matches this
				},
				columns: [
					{ data: 'name',            className: 'dt-body-left dt-head-left' },
					{ data: 'updatedDateTime', className: 'dt-body-left dt-head-left',
					render: v => v ? new Date(v).toLocaleString() : '' },
					{ data: 'userFullName',    className: 'dt-body-left dt-head-left' },
					{ data: 'validDomains',    className: 'dt-body-left dt-head-left' },
				],
				autoWidth: false,        // don't inject inline widths
				responsive: true,        // if you’ve loaded the responsive plugin
				dom: 'rt'
			});
		}

}
//====================================================================================


//====================================================================================
$(document).ready(function() {
//====================================================================================


	$( document ).tooltip();

	//-----------------------------------------------------------------------
	$( '#dateRange' ).selectmenu({
	//-----------------------------------------------------------------------
		change: function() {
			drawCharts( this.value );
		}
	});


	//-----------------------------------------------------------------------
	$( "#startDate" ).datepicker({
	//-----------------------------------------------------------------------
		
		dateFormat: 'mm/dd/yy',
		onClose: function( startDate ) {

			$( '#dateRange' ).val( 'custom' );
			$( '#dateRange' ).selectmenu( 'refresh' );
			drawCharts( 'custom' );

		},
	});


	//-----------------------------------------------------------------------
	$( "#endDate" ).datepicker({
	//-----------------------------------------------------------------------
		dateFormat: 'mm/dd/yy',
		onClose: async function( endDate ) {

			$( '#dateRange' ).val( 'custom' );
			$( '#dateRange' ).selectmenu( 'refresh' );
			drawCharts( 'custom' );

		},
	});



	//-----------------------------------------------------------------------
	$( '#userSelectionList' ).on( 'click', 'input.user', function() {
	//-----------------------------------------------------------------------
	
		clearTimeout(timer);
		timer = setTimeout( drawCharts, 900 ); // wait for 500ms after last change
	
	});



	//-----------------------------------------------------------------------
	$( 'div.pageHits' ).on( 'click', function() {
	//-----------------------------------------------------------------------
		// 				alert( 'view pageHits' );
		// 				const userList = getUserList();
		// 				const days = getDays();
		// 				window.location.href = `/sysopPageHits.asp?userList=${userList}&days=${days}`;
		window.location.href = `/sysopPageHits.asp`;
	});


	//-----------------------------------------------------------------------
	$( '#interstitials' ).on( 'change', function () {
	//-----------------------------------------------------------------------

		let startDate = $( '#startDate' ).val();
		let endDate = $( '#endDate' ).val();

		let interstitials;
		if ( $( '#interstitials' ).parent().hasClass( 'is-checked' ) ) {
			interstitials = false;
		} else {
			interstitials = true;
		}

		getSelectedUsers()
		.then( users => {
			debugger
			chartPageHits( startDate, endDate, users, interstitials );
		});

	});


//google.charts.setOnLoadCallback( drawCharts() );
	
	drawCharts( 'last seven days' );

}); // end of ready function

//====================================================================================



//====================================================================================
window.addEventListener('load', function() {
//====================================================================================

	const lastActivityTimes = document.querySelectorAll('td.lastActivityTime');
	if ( lastActivityTimes ) {
		for (i = 0; i < lastActivityTimes.length; ++i) {
			const timeOfLastActivity = dayjs(lastActivityTimes[i].textContent);
			if (timeOfLastActivity.isValid()) {
				lastActivityTimes[i].innerHTML = timeOfLastActivity.fromNow();
			}
		}
	}

});
//====================================================================================




