//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->
function MakeNegativeValueRed (element) {
//-- ------------------------------------------------------------------ -->
	
// 	var temp = element.childNodes[0].innerHTML;

	if (element.nodeType != 'TH') {

		var temp;
		var innerDiv = element.querySelector('div');
		
		if ( innerDiv ) {
			
			temp = innerDiv.textContent;	
	
		} else {
	
			temp = element.textContent;
		}
		
	
		if (temp) {
			if (!isNaN(temp)) {
				if (temp < 0) {
					element.childNodes[0].style.color = 'crimson';
				}
			} else {
				if (temp.indexOf('$') > - 1 || temp.indexOf('%') > -1) {
					if ((temp.indexOf('(') > - 1 && temp.indexOf(')') > - 1) || temp.indexOf('-')  > - 1) {
						element.style.color = 'crimson';
					}
				}
			}
		}
	
	}
	
}
