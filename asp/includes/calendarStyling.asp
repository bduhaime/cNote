<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

	<style>
		
		.calendarYear {
			border: none; 
			padding: 5px;
			
		}

		.calendarMonth, .calendarSameMonth {
			border: 1px solid black; 
			border-collapse: collapse; 
			text-align: center;
			font-weight: bold;
			padding: 5px;
		}

		.calendarDiffMonth {
			border: 1px solid black; 
			border-collapse: collapse; 
			text-align: center;
			font-weight: normal;
			padding: 5px;
			color: lightgrey;
		}
		
		.calendarWeekend {
			border: 1px solid black; 
			border-collapse: collapse; 
			text-align: center;
			font-weight: normal;
			padding: 5px;
			color: lightgrey;
		}
		
		.calendarHoliday {
			color: red;
		}

		.currentDay {
			background-color: lightblue;
		}
		
		#progressbar {
			position: absolute;
			top: 0;         /* adjust as needed */
			left: 0;        /* adjust as needed */
			z-index: 1000;  /* ensure it's on top */
			width: 100%;
		}


	</style>
