// ----------------------------------------------------------------------------------------
// Copyright 2017-2025, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

const analysis							= require( './analysis.js' );
const auth								= require( './auth.js' );
const calendar							= require( './calendar.js' );
const calendarLink 					= require( 'calendar-link' );
const coachMetrics					= require( './coachMetrics.js' );
const customerCallAttendees		= require( './customerCallAttendees.js' );
const customerCallNotes				= require( './customerCallNotes.js' );
const customerCallNoteHistory		= require( './customerCallNoteHistory.js' );
const customerCallNoteTypes		= require( './customerCallNoteTypes.js' );
const customerCalls					= require( './customerCalls.js' );
const customerCallTypes				= require( './customerCallTypes.js' );
const customerContacts				= require( './customerContacts.js' );
const customerContracts				= require( './customerContracts.js' );
const customerManagers				= require( './customerManagers.js' );
const customerMetrics				= require( './customerMetrics.js' );
const customerPriorities			= require( './customerPriorities.js' );
const customerStatuses				= require( './customerStatuses.js' );
const customers 						= require( './customers.js' );
const events							= require( './events.js' );
const eventDays						= require( './eventDays.js' );
const eventRegistrations			= require( './eventRegistrations.js' );
const exec								= require( './exec.js' );
const fdic								= require( './fdic.js' );
const fs 						= require( 'fs' );           		// full fs API (streams, sync, etc.)
const fsp 						= require( 'fs' ).promises; 		// promise-based async API
const health							= require( './health' );
const institutions					= require( './institutions.js' );
const jobStatus						= require( './jobStatus' );
const keyInitiatives					= require( './keyInitiatives.js' );
const learnerProfiles				= require( './learnerProfiles.js' );
const login								= require( './login.js' );
const marketing						= require( './marketing.js' );
const metrics							= require( './metrics.js' );
const mysteryShopping				= require( './mysteryShopping.js' );
const objectives						= require( './objectives.js' );
const opportunities 					= require( './opportunities.js' );
const path 								= require( 'path' );
const projects		 					= require( './projects.js' );
const projectManagers				= require( './projectManagers.js' );
const projectTemplates				= require( './projectTemplates.js' );
const roles								= require( './roles.js' );
const surveys							= require( './surveys.js' );
const sysop								= require( './sysop.js' );
const systemInfo						= require( './systemInfo.js' );
const tasks								= require( './tasks.js' );
const taskStatuses					= require( './taskStatuses.js' );
const tgimu								= require( './tgimu.js' );
const timezones						= require( './timezones.js' );
const userClients						= require( './userClients.js' );
const userCustomers					= require( './userCustomers.js' );
const userPermissions				= require( './userPermissions.js' );
const userRoles						= require( './userRoles.js' );
const users								= require( './users.js' );

const branches							= require( './cProfit/branches.js' );

// DAYJS =============================================================
global.dayjs 				= require( 'dayjs' );
const duration		 		= require( 'dayjs/plugin/duration' );
const quarterOfYear 		= require( 'dayjs/plugin/quarterOfYear' );
const relativeTime 		= require( 'dayjs/plugin/relativeTime' );
const timezone 			= require( 'dayjs/plugin/timezone' );
const utc 					= require( 'dayjs/plugin/utc' );
const isoWeek 				= require( 'dayjs/plugin/isoWeek' );
const dayOfYear 			= require( 'dayjs/plugin/dayOfYear' );
const isSameOrBefore		= require( 'dayjs/plugin/isSameOrBefore' );
const isBetween 			= require( 'dayjs/plugin/isBetween' );

global.dayjs.extend( duration );
global.dayjs.extend( quarterOfYear );
global.dayjs.extend( utc );
global.dayjs.extend( timezone );
global.dayjs.tz.setDefault( "America/Chicago" );
global.dayjs.extend( relativeTime );
global.dayjs.extend( isoWeek );
global.dayjs.extend( dayOfYear );
global.dayjs.extend( isSameOrBefore );
global.dayjs.extend( isBetween );

global.Holidays 			= require( 'date-holidays' );
global.hd 					= new Holidays('US');

//====================================================================


const US_BANK_HOLIDAYS = [
	"New Year's Day",
	'Martin Luther King Jr. Day',
	'Presidents Day',
	"Washington's Birthday",
	'Memorial Day',
	'Juneteenth National Independence Day',
	'Independence Day',
	'Labor Day',
	'Columbus Day',
	'Veterans Day',
	'Thanksgiving Day',
	'Christmas Day'
];


module.exports.set = function( https ) {


	// Q 							= require( 'q' );
	sql 						= require( 'mssql' );
	const path 				= require( 'path' );
	const dbConfig 		= require( path.join( "..", "config", "database.json" ) ).mssql;
	pool						= new sql.ConnectionPool( dbConfig );

	nodemailer 				= require( 'nodemailer' );
	jwt 						= require( 'jsonwebtoken' );
	moment					= require( 'moment-timezone' );
	utilities				= require( '../utilities' );
	md5 						= require( 'md5' );
	generator 				= require( 'generate-password' );
	url						= require( 'url' );
	btoa						= require( 'btoa' );
	cheerio					= require( 'cheerio' );

	analysis.set( https );
	auth.set( https );
	// arraySort.set( https );
	calendar.set( https );
	// calendarLink.set( https );
	coachMetrics.set( https );
	customerCallAttendees.set( https );
	customerCallNotes.set( https );
	customerCallNoteHistory.set( https );
	customerCallNoteTypes.set( https );
	customerCalls.set( https );
	customerCallTypes.set( https );
	customerContacts.set( https );
	customerContracts.set( https );
	customerManagers.set( https );
	customerMetrics.set( https );
	customerPriorities.set( https );
	customerStatuses.set( https );
	customers.set( https );
	events.set( https );
	eventDays.set( https );
	eventRegistrations.set( https );
	exec.set( https );
	fdic.set( https );
	// fs.set( https );
	// fsp.set( https );
	// holidays.set( https);
	health.set( https );
	institutions.set( https );
	jobStatus.set( https );
	learnerProfiles.set( https );
	keyInitiatives.set( https );
	login.set( https );
	metrics.set( https );
	marketing.set( https );
	mysteryShopping.set( https );
	objectives.set( https );
	opportunities.set( https );
	// path.set( https );
	projects.set( https );
	projectManagers.set( https );
	projectTemplates.set( https );
	roles.set( https );
	surveys.set( https );
	sysop.set( https );
	systemInfo.set( https );
	tasks.set( https );
	taskStatuses.set( https );
	tgimu.set( https );
	timezones.set( https );
	userClients.set( https );
	userCustomers.set( https );
	userPermissions.set( https );
	userRoles.set( https );
	users.set( https );

	branches.set( https );

	//====================================================================================
	// app.get('/', (req, res) => res.end('hello'))
	//====================================================================================


	//====================================================================================
	https.get('/', (req, res) => res.end('Shhh... hello'));
	//====================================================================================


	//====================================================================================
	pool.connect( function( err ) {
	//====================================================================================

		if ( err ) {
			logger.log({ level: 'error', label: 'controllers/index.js', message: 'Cannot connect to pool: '+err, user: 'system' });
		} else {
			logger.log({ level: 'debug', label: 'controllers/index.js', message: 'Connected to pool', user: 'system' });
		}

	})
	//====================================================================================


}
