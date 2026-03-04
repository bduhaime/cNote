<!DOCTYPE html>
<!-- ------------------------------------------------------------------ -->
<!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
<!-- ------------------------------------------------------------------ -->

<!-- #include file="includes/security.asp" -->
<!-- #include file="includes/dbug.asp" -->
<!-- #include file="includes/dataconnection.asp" -->
<!-- #include file="includes/createDisconnectedRecordset.asp" -->
<!-- #include file="includes/userPermitted.asp" -->
<% 
title = "Dialog Test" 
%>
<html>

<head>
	<!-- #include file="includes/globalHead.asp" -->
	<link rel="stylesheet" type="text/css" href="dialog-polyfill.css" />
</head>

<body>
  <button id="show-dialog1" type="button" class="mdl-button">Show Dialog 1</button>
  <button id="show-dialog2" type="button" class="mdl-button">Show Dialog 2</button>
  
  <dialog id="dialog1" class="mdl-dialog">
    <h4 class="mdl-dialog__title">Allow data collection?</h4>
    <div class="mdl-dialog__content">
      <p>
        This is the first dialog. Allowing us to collect data will let us get you the information you want faster.
      </p>
    </div>
    <div class="mdl-dialog__actions">
      <button type="button" class="mdl-button ">Agree</button>
      <button type="button" class="mdl-button close">Disagree</button>
    </div>
  </dialog>
  
  <dialog id="dialog2" class="mdl-dialog">
    <h4 class="mdl-dialog__title">Allow data collection?</h4>
    <div class="mdl-dialog__content">
      <p>
        This is the second dialog. Allowing us to collect data will let us get you the information you want faster.
      </p>
    </div>
    <div class="mdl-dialog__actions">
      <button type="button" class="mdl-button ">Agree</button>
      <button type="button" class="mdl-button close">Disagree</button>
    </div>
  </dialog>
  
  
 <script src="dialog-polyfill.js"></script>  
 <script>
    var dialog1 = document.querySelector('#dialog1');
    var dialog2 = document.querySelector('#dialog2');
    
    var showDialogButton1 = document.querySelector('#show-dialog1');
    var showDialogButton2 = document.querySelector('#show-dialog2');
    
    if (! dialog1.showModal) {
      dialogPolyfill.registerDialog(dialog1);
    }
    if (! dialog2.showModal) {
	    dialogPolyfill.registerDialog(dialog2);
    }
    
    showDialogButton1.addEventListener('click', function() {
      dialog1.showModal();
    });
    dialog1.querySelector('.close').addEventListener('click', function() {
      dialog1.close();
    });

    showDialogButton2.addEventListener('click', function() {
      dialog2.showModal();
    });
    dialog2.querySelector('.close').addEventListener('click', function() {
      dialog2.close();
    });
  </script>
</body>

</html>