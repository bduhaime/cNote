<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

	<div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
  <header class="mdl-layout__header">
    <div class="mdl-layout__header-row">
      <!-- Title -->
      <span class="mdl-layout-title"><% =title %></span>
      <!-- Add spacer, to align navigation to the right -->
      <div class="mdl-layout-spacer"></div>
      <!-- Navigation. We hide it in small screens. -->
      
		<!-- Left aligned menu below button -->
		<nav class="mdl-navigation">
		  <a id="submenu" class="mdl-navigation__link" href="#">Link</a>
		  <a id="submenu2" class="mdl-navigation__link" href="#">Link</a>
		  <a class="mdl-navigation__link" href="">Link</a>
		  <a class="mdl-navigation__link" href="">Link</a>
		</nav>
		
		<!-- sub menu only visible when clicked on the link above -->
		<ul class="mdl-menu mdl-menu--bottom-left mdl-js-menu mdl-js-ripple-effect"
		    for="submenu">
		  <li class="mdl-menu__item">Some Action</li>
		  <li class="mdl-menu__item">Another Action</li>
		  <li disabled class="mdl-menu__item">Disabled Action</li>
		  <li class="mdl-menu__item">Yet Another Action</li>
		</ul>
		
		<!-- sub menu only visible when clicked on the link above -->
		
		<ul class="mdl-menu mdl-menu--bottom-left mdl-js-menu mdl-js-ripple-effect"
		    for="submenu2">
		  <li class="mdl-menu__item">2 Some Action</li>
		  <li class="mdl-menu__item">2 Another Action</li>
		  <li disabled class="mdl-menu__item">Disabled Action</li>
		  <li class="mdl-menu__item">2 Yet Another Action</li>
		</ul>

    </div>
  </header>
  
  
  
  <div class="mdl-layout__drawer">
    <span class="mdl-layout-title"><% =title %></span>
    <nav class="mdl-navigation">
		  <a id="submenu3" class="mdl-navigation__link" href="#">Link</a>
		  <a id="submenu4" class="mdl-navigation__link" href="#">Link</a>
      <a class="mdl-navigation__link" href="security.asp">Security</a>
      <a class="mdl-navigation__link" href="login.asp?cmd=logout">Logout</a>
    </nav>

		<ul class="mdl-menu mdl-menu--bottom-left mdl-js-menu mdl-js-ripple-effect"
		    for="submenu3">
		  <li class="mdl-menu__item">Some Action</li>
		  <li class="mdl-menu__item">Another Action</li>
		  <li disabled class="mdl-menu__item">Disabled Action</li>
		  <li class="mdl-menu__item">Yet Another Action</li>
		</ul>

  </div>
