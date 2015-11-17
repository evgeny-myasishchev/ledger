(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .config(config);

  config.$inject = ['$routeProvider'];

  function config($routeProvider) {
    $routeProvider
      .when('/report', {
        templateUrl: "report-transactions.html",
        controller: 'ReportTransactionsController'
      })
      .when('/accounts/:accountSequentialNumber/report', {
        templateUrl: "report-transactions.html",
        controller: 'ReportTransactionsController'
      })
      .when('/pending-transactions', {
        templateUrl: "pending-transactions.html",
        controller: 'PendingTransactionsController'
      });
  }
})();