!function() {
  'use strict';
  
  angular
    .module('homeApp', [
      'ErrorHandler', 
      'ngRoute', 
      'ledgerDirectives', 
      'ledgersProvider', 
      'tagsProvider', 
      'accountsApp', 
      'transactionsApp', 
      'profileApp'
    ])
    .config(protectFromForgery);

  protectFromForgery.$inject = ['$httpProvider'];

  function protectFromForgery($httpProvider) {
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = jQuery('meta[name=csrf-token]').attr('content')
  }
}();