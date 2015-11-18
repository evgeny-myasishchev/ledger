(function () {  
  'use strict';

  angular
    .module('homeApp')
    .filter('promiseStatus', promiseStatus);

  function promiseStatus() {
    return function(promise, status) {
      status.inProgress = true;
      status.resolved = false;
      status.rejected = false;
      promise
        .then(function() {
          status.resolved = true;
        })
        .catch(function() {
          status.rejected = true;
        })
        .finally(function() {
          status.inProgress = false;
        });
    }
  }
})();