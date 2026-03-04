<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<div class="mdl-grid">

	<div class="mdl-layout-spacer"></div>
	
	<div class="mdl-cell mdl-cell--4-col">
	
	
		<table class="mdl-data-table mdl-js-data-table">
			<!-- 	<table class="mdl-data-table mdl-js-data-table mdl-data-table--selectable mdl-shadow--2dp"> -->
			<thead>
				<tr>
					<th class="mdl-data-table__cell--numeric"></th>
					<th class="mdl-data-table__cell--non-numeric">Name</th>
					<th class="mdl-data-table__cell--non-numeric">City</th>
					<th class="mdl-data-table__cell--non-numeric">State</th>
					<th class="mdl-data-table__cell--non-numeric">Status</th>
				</tr>
			</thead>
			<tbody> 
				<tr>
					<td class="mdl-data-table__cell--non-numeric"><a href="customerList.asp"><img src="/images/ic_arrow_back_black_24dp_1x.png"></a></td>
					<td class="mdl-data-table__cell--non-numeric"><% =customerName %></td>
					<td class="mdl-data-table__cell--non-numeric"><% =customerCity %></td>
					<td class="mdl-data-table__cell--non-numeric"><% =customerState %></td>
					<td class="mdl-data-table__cell--non-numeric"><% =customerStatus %></td>
				</tr>	
			</tbody>
		</table>		
	
	</div>

	<div class="mdl-layout-spacer"></div>
	
</div><!-- end grid -->
