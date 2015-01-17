//= require_self
//= require_tree .

var transactionsApp = (function() {
	var transactionsApp = angular.module('transactionsApp', ['ErrorHandler', 'ngRoute', 'UUID', 'ledgerHelpers', 'accountsApp']);
	
	transactionsApp.provider('transactions', function() {
		var pendingTransactionsCount = 0;
		
		this.setPendingTransactionsCount = function(value) {
			pendingTransactionsCount = value;
		};
		
		this.$get = [function() {
			return {
				getPendingCount: function() {
					return pendingTransactionsCount;
				},
				
				processReportedTransaction: function(transaction) {
					
				},
				
				processApprovedTransaction: function(transaction) {
					
				}
			}
		}];
	});
	
	transactionsApp.config(['$routeProvider', function($routeProvider) {
			$routeProvider.when('/report', {
				templateUrl: "report-transactions.html",
				controller: 'ReportTransactionsController'
			});
			$routeProvider.when('/accounts/:accountSequentialNumber/report', {
				templateUrl: "report-transactions.html",
				controller: 'ReportTransactionsController'
			});
			$routeProvider.when('/pending-transactions', {
				templateUrl: "pending-transactions.html",
				controller: 'PendingTransactionsController'
			});
		}
	]);
	return transactionsApp;
})();