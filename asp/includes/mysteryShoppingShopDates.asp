<table class="control">
	<tr>
		<th>Shop Dates:</th>
		<td>
			<select name="dateRange" id="dateRange">
				<option value="allDates">All dates</option>
				<option value="monthToDate">Month to date</option>
				<option value="quarterToDate">Quarter to date</option>
				<option value="yearToDate">Year to date</option>
				<option value="mostRecent30">Most recent 30 days</option>
				<option value="mostRecent60">Most recent 60 days</option>
				<option value="mostRecent90">Most recent 90 days</option>
				<option value="mostRecent12Months" selected>Most recent 12 months</option>
				<option value="custom" disabled>Custom</option>
			</select>
		</td>
	</tr>
	<tr>
		<th>Start Date:</th>
		<td><input id="startDate" type="text" class="datepicker" readonly="readonly"></td>
	</tr>
	<tr>
		<th>End Date:</th>
		<td><input id="endDate" type="text" class="datepicker" readonly="readonly"></td>
	</tr>
	<tr>
		<th>Branch:</th>
		<td>
			<label for="branchSelectMenu"></label>
			<select name="branchSelectMenu" id="branchSelectMenu">
				<option value="all">All Branches</option>
			</select>
		</td>

	</tr>

</table>