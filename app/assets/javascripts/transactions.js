var transactions = (function() {
	var transactions = angular.module('transactions', ['ErrorHandler', 'ngRoute', 'ledgerHelpers', 'homeApp']);
	transactions.config(['$routeProvider', function($routeProvider) {
			$routeProvider.when('/accounts/:accountSequentialNumber/report', {
				templateUrl: "report.html",
				controller: 'ReportTransactionsController'
			});
		}
	]);
	return transactions;
})();