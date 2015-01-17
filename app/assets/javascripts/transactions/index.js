//= require_self
//= require_tree .

var transactionsApp = (function() {
	var transactionsApp = angular.module('transactionsApp', ['ErrorHandler', 'ngRoute', 'UUID', 'ledgerHelpers', 'accountsApp']);
	
	transactionsApp.provider('transactions', function() {
		var pendingTransactionsCount = 0;
		
		this.setPendingTransactionsCount = function(value) {
			pendingTransactionsCount = value;
		};
		
		this.$get = ['accounts', function(accounts) {
			return {
				getPendingCount: function() {
					return pendingTransactionsCount;
				},
				
				processReportedTransaction: function(command) {
					var account = accounts.getById(command.account_id);
					if(command.type_id == Transaction.incomeId || command.type_id == Transaction.refundId) {
						account.balance += command.amount;
					} else if(command.type_id == Transaction.expenceId) {
						account.balance -= command.amount;
					}
					if(command.is_transfer) {
						var receivingAccount = accounts.getById(command.receiving_account_id);
						receivingAccount.balance += command.amount_received;
					}
					command.tag_ids = jQuery.map(command.tag_ids, function(tag_id) {
						return '{' + tag_id + '}';
					}).join(',');
				},
				
				processApprovedTransaction: function(transaction) {
					this.processReportedTransaction(transaction);
					pendingTransactionsCount--;
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