// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

// dbConfig = require('../config/database.json').mssql;
	let db = require('../config/db.js');

	let {
		Editor,
		Field,
		Validate,
		Format,
		Options
	} = require("datatables.net-editor-server");

	//====================================================================================
	https.all('/api/customerContracts', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		let editor = new Editor( db, 'contracts' );

		editor.fields(

			new Field( "customer.name", "customerName" )
				.set( false ),

			new Field( "contracts.cert", "cert" )
				.validator( Validate.notEmpty() ),

			new Field( "contracts.active", "active" ),

			new Field( "contracts.product", "product" ),

			new Field( "contracts.contractType", "contractType" )
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.contractLevel", "contractLevel" )
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.contractRenewalType", "contractRenewalType" )
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.term", "term" )
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.effectiveDate", "effectiveDate" )
				.getFormatter( (val, data) => {
					if ( val ) {
						return dayjs.utc( val ).format('YYYY-MM-DD')
					} else {
						return null
					}
				})
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.termLetterDate", "termLetterDate" )
				.getFormatter( (val, data) => {
					if ( val ) {
						return dayjs.utc( val ).format('YYYY-MM-DD')
					} else {
						return null
					}
				})
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.supercededDate", "supersededDate" )
				.getFormatter( (val, data) => {
					if ( val ) {
						return dayjs.utc( val ).format('YYYY-MM-DD')
					} else {
						return null
					}
				})
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.mom_bfl_startDate", "mom_bfl_startDate" )
				.getFormatter( (val, data) => {
					if ( val ) {
						return dayjs.utc( val ).format('YYYY-MM-DD')
					} else {
						return null
					}
				})
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.expirationDate", "expirationDate" )
				.getFormatter( (val, data) => {
					if ( val ) {
						return dayjs.utc( val ).format('YYYY-MM-DD')
					} else {
						return null
					}
				})
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.initialMRRAmt", "initialMRRAmt" )
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.cpiStartDate", "cpiStartDate" )
				.getFormatter( (val, data) => {
					if ( val ) {
						return dayjs.utc( val ).format('YYYY-MM-DD')
					} else {
						return null
					}
				})
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.cpiIncreasePct", "cpiIncreasePct" )
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.increaseFromAssetGrowthAmt", "increaseFromAssetGrowthAmt" )
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.totalMonthlyIncreaseAmt", "totalMonthlyIncreaseAmt" )
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.priorYearIncreasePct", "priorYearIncreasePct" )
				.setFormatter( Format.ifEmpty( null ) ),

			new Field( "contracts.notes", "notes" )
				.setFormatter( Format.ifEmpty( null ) )

		);

		editor.leftJoin( "customer", "customer.cert", "=", "contracts.cert" );

		if ( req.query.customerID ) {
			if ( parseInt( req.query.customerID ) != 0 ) {
				editor.where({ 'customer.id': parseInt( req.query.customerID ) });
			}
		}

		await editor.process( req.body );
		res.json( editor.data() );

	});
	//====================================================================================


	//====================================================================================
	https.all('/api/customerContracts/products', utilities.jwtVerify, async function(req, res) {
	//====================================================================================

		let editor = new Editor( db, 'contractProducts' );

		editor.fields(
			new Field( "contractProducts.id", "id" ),
			new Field( "contractProducts.name", "name" )
		)

		if ( req.query.productID ) {
			if ( req.query.product != '' ) {
				editor.where({ 'contractProducts.id': req.query.customerID });
			}
		}

		await editor.process( req.body );
		res.json( editor.data() );

	});
	//====================================================================================



}
