// ----------------------------------------------------------------------------------------
// Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved.
// ----------------------------------------------------------------------------------------

module.exports.set = function( https ) {

	dbConfig = require('../../config/database.json').mssql;

	//====================================================================================
	https.post('/api/cProfit/branches', utilities.jwtVerify, (req, res) => {
	//====================================================================================

		if ( !req.body.customerID ) return res.status( 400 ).send( 'Parameter missing' )

		SQL 	= 	"select "
				+		"[branch description] as branchDescription, "
				+		"sum(loanCount) 		as loanCount, "
				+		"sum(loanBalance) 	as loanBalance, "
				+		"sum(loanProfit) 		as loanProfit, "
				+		"case when sum(loanBalance) <> 0 then sum(loanInterest) / sum(loanBalance) else 0 end as loanInterest, "
				+		"sum(depositCount) 	as depositCount, "
				+		"sum(depositBalance) as depositBalance, "
				+		"sum(depositProfit) 	as depositProfit, "
				+		"case when sum(depositBalance) <> 0 then sum(depositInterest) / sum(depositBalance) else 0 end as depositInterest, "
				+		"sum(otherCount) 		as otherCount, "
				+		"sum(otherBalance) 	as otherBalance, "
				+		"sum(otherProfit) 	as otherProfit, "
				+		"case when sum(otherBalance) <> 0 then sum(otherInterest) / sum(otherBalance) else 0 end as otherInterest, "
				+		"sum(loanCount) + sum(depositCount) + sum(otherCount) as totalCount, "
				+		"sum(loanBalance) + sum(depositBalance) + sum(otherBalance) as totalBalance, "
				+		"sum(loanProfit) + sum(depositProfit) + sum(otherProfit) as totalProfit "
				+	"from ( "
				+		"select "
				+			"[branch description], "
				+			"case when [loan deposit other] = 'Loan' 		then 1 									else 0 end as loanCount, "
				+			"case when [loan deposit other] = 'Loan' 		then balance							else 0 end as loanBalance, "
				+			"case when [loan deposit other] = 'Loan' 		then profit								else 0 end as loanProfit, "
				+			"case when [loan deposit other] = 'Loan' 		then [interest rate x balance] 	else 0 end as loanInterest, "
				+			"case when [loan deposit other] = 'Deposit' 	then 1 									else 0 end as depositCount, "
				+			"case when [loan deposit other] = 'Deposit' 	then balance							else 0 end as depositBalance, "
				+			"case when [loan deposit other] = 'Deposit' 	then profit								else 0 end as depositProfit, "
				+			"case when [loan deposit other] = 'Deposit' 	then [interest rate x balance] 	else 0 end as depositInterest, "
				+			"case when [loan deposit other] = 'Other' 	then 1 									else 0 end as otherCount, "
				+			"case when [loan deposit other] = 'Other' 	then balance							else 0 end as otherBalance, "
				+			"case when [loan deposit other] = 'Other' 	then profit								else 0 end as otherProfit, "
				+			"case when [loan deposit other] = 'Other' 	then [interest rate x balance] 	else 0 end as otherInterest "
				+		"from pr_pqwebarchive archive "
				+		"where [Account Holder Number] not in ('0','Manually Added Accounts') "
				+		"and [Branch Description] not in ('Treasury','Manually Added Accounts') "
				+		"and [Officer Name] <> 'Treasury' "
				+		"and archive.customerID = @customerID "
				// +		centilePredicate
				// +		decilePredicate
				// +		ninetyNinePredicate
				// +		gradePredicate
				// +		flagPredicate
				// +		branchPredicate
				// +		officerPredicate
				// +		productPredicate
				// +		accountHolderPredicate
				+		") as x "
				+	"group by [branch description] "
				+	"order by [branch description] "

		sql.connect(dbConfig).then( pool => {
			return pool.request()
				.input( 'customerID', sql.BigInt, req.body.customerID )
				.query( SQL )
		}).then( result  => {
			res.json( result.recordset )
		}).catch( err => {
			console.error( err )
			res.status( 500 ).send( 'Unexpected database error encountered' )
		})

	})
	//====================================================================================


}
