//-- ------------------------------------------------------------------ -->
//-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
//-- ------------------------------------------------------------------ -->

document.getElementById('startDate').parentNode.classList.add('is-dirty');
document.getElementById('dueDate').parentNode.classList.add('is-dirty');

var completionDateElement = document.getElementById('completionDate');

completionDateElement.classList.add('is-dirty');
completionDateElement.parentNode.MaterialTextfield.checkDirty();

document.getElementById('taskDaysDurationEst').parentNode.classList.add('is-dirty');
