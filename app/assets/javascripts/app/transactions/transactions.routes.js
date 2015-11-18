(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .config(config);

  config.$inject = ['$routeProvider'];

  function config($routeProvider) {
    $routeProvider
      .when('/report', {
        templateUrl: 'app/transactions/report/report.html',
        controller: 'ReportTransactionsController',
        controllerAs: 'vm'
      })
      .when('/accounts/:accountSequentialNumber/report', {
        templateUrl: 'app/transactions/report/report.html',
        controller: 'ReportTransactionsController',
        controllerAs: 'vm'
      })
      .when('/pending-transactions', {
        templateUrl: "app/transactions/pending/pending-transactions.html",
        controller: 'PendingTransactionsController',
        controllerAs: 'vm'
      });
  }
})();