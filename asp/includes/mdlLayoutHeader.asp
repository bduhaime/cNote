<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<div class="mdl-spinner mdl-js-spinner is-active" style="position: absolute; z-index: 1000; top: 50%; left: 50%;"></div>

<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
<header class="mdl-layout__header">
	<div class="mdl-layout__header-row">
		<!-- Title -->
		<span class="mdl-layout-title"><% =title %></span>
		
		<!-- Add spacer, to align navigation to the right -->
		<div class="mdl-layout-spacer"></div>
		
		<!-- #include file="mdlLayoutNavLarge.asp" -->

	</div>
</header>

<div class="mdl-layout__drawer">
	<span class="mdl-layout-title"><% =title %></span>
	<nav class="mdl-navigation">

		<% if lCase(session("dbName")) = "csuite" then %>
			<a class="mdl-navigation__link" href="/adminHome.asp">Home</a>
		<% else %>
			<a class="mdl-navigation__link" href="/home.asp">Home</a>
		<% end if %>

		<% if userPermitted(2) then %><a class="mdl-navigation__link" href="admin.asp">Admin</a><% end if %>

		<a class="mdl-navigation__link" href="/ajax/logout.asp?cmd=manual">Logout</a>
		
	</nav>


</div>

<div id="dialog-sessionTimeout" title="Session Timeout" style="display: none; align-items: flex-end;">
  <span class="material-symbols-outlined" style="float:left; font-size: 48px; color: orange; margin-right: 12px;">warning</span>
  <span style="text-align: bottom;">Your session will time out soon: <span id="countdownTimer"></span></span>
</div>
<style>
	div:has(#dialog-sessionTimeout) .ui-dialog-titlebar {
		background-color: rgb(103,58,183);
		color: #ffffff;
	}

	div.ui-dialog:has(#dialog-sessionTimeout) {
		box-shadow: 0 0 30px rgba(0, 0, 0, 0.5);
	}	
</style>
