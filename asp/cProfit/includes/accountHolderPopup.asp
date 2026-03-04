<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->
<% dbug("start of cProfit/includes/accountHolderPopup.asp") %>
<div id="addendaContextMenu" data-customerID="<% =customerID %>" style="display: none; width: 600px; position: absolute; background: white;" class="cNoteAddendaContextMenu mdl-shadow--2dp"> 
	<div class="accountHolderName" style="background-color: lightgrey; padding: 10px;"></div>
	<table style="width: 100%; border: none;">
		<tr>
			<td style="border: none; width: 35%; vertical-align: top">
				<div style="border-bottom: solid lightgrey 1px; overflow: auto; height: 200px;">
					<ul class="accountHolderFlags" style="padding-left: 5px;"></ul>
				</div>
			</td>
			<td style="border: none; vertical-align: top;">
				<div style="border-bottom: solid lightgrey 1px; overflow: auto; height: 200px;">
					<table class="accountHolderComments" style="border-collapse: collapse; width: 100%;"></table>
				</div>
			</td>
		</tr>
	</table>
	
	<table style="width: 100%">
		<tr>
			<td style="text-align: left; border: none; width: 87%">
				<textarea id="newComment" class="newComment" style="width: 100%; font-size: 13px;" rows= "3" placeholder="Add a comment..." ></textarea>
			</td>
			<td style="text-align: left; border: none;">
				<button class="mdl-button mdl-js-button mdl-button--icon cancel" disabled>
					<i class="material-icons">cancel</i>
				</button>
				<button class="mdl-button mdl-js-button mdl-button--icon save" disabled>
					<i class="material-icons">save</i>
				</button>
			</td>
		</tr>
	</table>
</div>
<% dbug("end of cProfit/includes/accountHolderPopup.asp") %>
