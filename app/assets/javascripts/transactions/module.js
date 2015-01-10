var transactionsApp = (function() {
	var transactionsApp = angular.module('transactionsApp', ['ErrorHandler', 'ngRoute', 'UUID', 'ledgerHelpers', 'accountsApp']);
	transactionsApp.config(['$routeProvider', function($routeProvider) {
			$routeProvider.when('/report', {
				templateUrl: "report-transactions.html",
				controller: 'ReportTransactionsController'
			});
			$routeProvider.when('/accounts/:accountSequentialNumber/report', {
				templateUrl: "report-transactions.html",
				controller: 'ReportTransactionsController'
			});
		}
	]);
	return transactionsApp;
})();