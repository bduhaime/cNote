<html>

	<head>


		<script src="/list.min.js"></script>
		<script>

		window.addEventListener('load', function() {

			var options = {
				valueNames: [
					'one',
					'two',
					'three' 
				]
			};
			
			var list	= new List(document.querySelector('body'), options);
			
		});

			
		</script>

		<style>
			.colHeader {
				border: solid black 1px;
				font-weight: bold;
				display: inline-block
			}
			
			.colData {
				border: solid crimson 1px;
				display: inline-block
			}
			.colExtra {
				border: solid green 1px;
			}
			
			.medium {
				width: 200px;
			}
			
			.hideMe {
				display: none;
			}
			
			
		</style>
	</head>
	
	<body>
	
		<table>
			<thead>
				<tr>
					<th class="colHeader medium sort" data-sort="one">Header1</th>
					<th class="colHeader medium sort" data-sort="two">Header2</th>
					<th class="colHeader medium sort" data-sort="three">Header3</th>
				</tr>
			</thead>
			<tbody class="list">
				<tr>
					<td class="colData medium one">A1</td>
					<td class="colData medium two">A2</td>
					<td class="colData medium three">A3</td>
				</tr>
				<tr>
					<td class="colData medium hideMe one">A1</td>
					<td class="colData medium hideMe two">A2</td>
					<td class="colData medium hideMe three">A3</td>
					<td colspan="3" class="colExtra">A4</td>
				</tr>
				<tr>
					<td class="colData medium one">B1</td>
					<td class="colData medium two">B2</td>
					<td class="colData medium three">B3</td>
				</tr>
				<tr>
					<td class="colData medium hideMe one">B1</td>
					<td class="colData medium hideMe two">B2</td>
					<td class="colData medium hideMe three">B3</td>
					<td colspan="3" class="colExtra">B4</td>
				</tr>
				<tr>
					<td class="colData medium one">C1</td>
					<td class="colData medium two">C2</td>
					<td class="colData medium three">C3</td>
				</tr>
				<tr>
					<td class="colData medium hideMe one">C1</td>
					<td class="colData medium hideMe two">C2</td>
					<td class="colData medium hideMe three">C3</td>
					<td colspan="3" class="colExtra">C4</td>
				</tr>
		
	</body>

</html>