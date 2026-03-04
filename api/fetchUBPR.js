
	const axios 	= require("axios")
	const cheerio 	= require("cheerio")
	
	async function fetchHTML(url) {
	  const { data } = await axios.get(url)
	  return cheerio.load(data)
	}
	
	(async function() {
		const $ = await fetchHTML("https://cdr.ffiec.gov/Public/Reports/UbprReport.aspx?rptid=283&idrssd=343903&rptCycleIds=125,120,114,107,101&peerGroupType=UBPPD186&supplemental=UBPPD186")

		// print something....
		console.log( "length of $('.UbprReportDataRow'): " + $('.UbprReportDataRow') )

		// // Print the full HTML
		console.log(`Site HTML: ${$.html()}\n\n`)
		// 
		// // Print some specific page content
		// console.log(`First h1 tag: ${$('h1').text()}`)
		
	})()