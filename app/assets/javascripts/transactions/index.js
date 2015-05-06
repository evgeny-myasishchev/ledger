//= require_self
//= require_tree .

var Transaction = {
    incomeId: 1, incomeKey: 'income',
    expenseId: 2, expenseKey: 'expense',
    refundId: 3, refundKey: 'refund',
	transferId: undefined, transferKey: 'transfer',
	l10n: {}
};
Transaction.TypeIdByKey = {};
Transaction.TypeKeyById = {};
Transaction.TypeById = {};

Transaction.l10n[Transaction.incomeKey] = 'Income';
Transaction.l10n[Transaction.expenseKey] = 'Expense';
Transaction.l10n[Transaction.refundKey] = 'Refund';
Transaction.l10n[Transaction.transferKey] = 'Transfer';

jQuery.each([Transaction.incomeKey, Transaction.expenseKey, Transaction.refundKey, Transaction.refundKey], function(i, key) {
	var id = Transaction[key + 'Id'];
	var type = {id: id, key: key, t: function() { return Transaction.l10n[key]; }};
	Transaction.TypeIdByKey[key] = id;
	Transaction.TypeKeyById[id] = key;
	Transaction.TypeById[id] = type;
	Transaction[key] = type;
});
Transaction.regular = [Transaction.income, Transaction.expense, Transaction.refund];

var transactionsApp = (function() {
	var transactionsApp = angular.module('transactionsApp', ['ErrorHandler', 'ngRoute', 'UUID', 'ledgerHelpers', 'accountsApp']);
	
	transactionsApp.provider('transactions', function() {
		var pendingTransactionsCount = 0;
		
		this.setPendingTransactionsCount = function(value) {
			pendingTransactionsCount = value;
		};
		
		this.$get = ['$http', 'accounts', function($http, accounts) {
			return {
				getPendingCount: function() {
					return pendingTransactionsCount;
				},
				
				processReportedTransaction: function(command) {
					var account = accounts.getById(command.account_id);
					if(command.type_id == Transaction.incomeId || command.type_id == Transaction.refundId) {
						account.balance += command.amount;
					} else if(command.type_id == Transaction.expenseId) {
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
				},
				
				moveTo: function(transaction, targetAccount) {
					var sourceAccount = accounts.getById(transaction.account_id);
					return $http.post('transactions/' + transaction.transaction_id + '/move-to/' + targetAccount.aggregate_id).then(function() {
						if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
							sourceAccount.balance -= transaction.amount;
							targetAccount.balance += transaction.amount;
							if(transaction.is_transfer) transaction.receiving_account_id = targetAccount.aggregate_id;
						} else if(transaction.type_id == Transaction.expenseId) {
							sourceAccount.balance += transaction.amount;
							targetAccount.balance -= transaction.amount;
							if(transaction.is_transfer) transaction.sending_account_id = targetAccount.aggregate_id;
						}
						transaction.account_id = targetAccount.aggregate_id;
						transaction.has_been_moved = true;
					});
				},
				
				convertType: function(transaction, typeId) {
					var account = accounts.getById(transaction.account_id);
					return $http.put('accounts/' + account.aggregate_id + '/transactions/' + transaction.transaction_id + '/convert-type/' + typeId).then(function() {
						if(typeId == Transaction.expenseId && (transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId)) {
							account.balance -= transaction.amount * 2;
						} else if(transaction.type_id == Transaction.expenseId) {
							account.balance += transaction.amount * 2;
						}
						transaction.type_id = typeId;
					});
				}
			}
		}];
	});
	
	transactionsApp.filter('transactionTypeName', function() {
		return function(typeId) {
			return Transaction.TypeById[typeId].t();
		}
	})
	
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