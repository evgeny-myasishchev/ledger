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
        templateUrl: "app/transactions/pending/pending-transactions.html",
        controller: 'PendingTransactionsController',
        controllerAs: 'vm'
      });
  }
})();