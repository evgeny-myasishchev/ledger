!function() {
	var transactionsApp = angular.module('transactionsApp');
	
	transactionsApp.provider('pendingTransactions', function() {
		var pendingTransactionsCount = 0;
		
		this.setPendingTransactionsCount = function(value) {
			pendingTransactionsCount = value;
		};
		
		this.$get = [function() {
			return {
				getCount: function() {
					return pendingTransactionsCount;
				},
				
				approve: function(pendingTransaction, approvalData) {
					
				}
			}
		}];
	});
	
	transactionsApp.controller('PendingTransactionsController', ['$scope', '$http', 'accounts',
	function ($scope, $http, accounts) {
		$http.get('pending-transactions.json').success(function(data) {
			var transactions = data;
			jQuery.each(transactions, function(i, t) {
				if(t.date) t.date = new Date(t.date);
			});
			$scope.transactions = transactions;
			$scope.accounts = accounts.getAllOpen();
			
			$scope.approve = function() {
				console.log($scope.pendingTransaction);
			};
			
			$scope.startReview = function(transaction) {
				$scope.pendingTransaction = {
					aggregate_id: transaction.aggregate_id,
					amount: transaction.amount,
					date: transaction.date,
					tag_ids: transaction.tag_ids,
					comment: transaction.comment,
					account_id: transaction.account_id,
					type_id: transaction.type_id
				};
			};
			
			$scope.stopReview = function() {
				$scope.pendingTransaction = null;
			};
			
			$scope.startReview(transactions[0]);
		});
	}]);
}();