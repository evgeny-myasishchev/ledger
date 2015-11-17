(function () {  
  'use strict';

  angular
    .module('transactionsApp', [
      'ErrorHandler', 
      'ngRoute', 
      'UUID', 
      'ledgerHelpers', 
      'accountsApp',
      'templates'
    ]);
})();