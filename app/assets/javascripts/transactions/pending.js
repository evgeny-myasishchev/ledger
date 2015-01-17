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
	
	transactionsApp.controller('PendingTransactionsController', ['$scope', '$http', 'accounts', 'money',
	function ($scope, $http, accounts, money) {
		$scope.approvedTransactions = [];
		$http.get('pending-transactions.json').success(function(data) {
			var transactions = data;
			jQuery.each(transactions, function(i, t) {
				if(t.date) t.date = new Date(t.date);
			});
			$scope.transactions = transactions;
			$scope.accounts = accounts.getAllOpen();
		});
		
		$scope.adjustAndApprove = function() {
			$http.post('pending-transactions/' + $scope.pendingTransaction.aggregate_id + '/adjust-and-approve', $scope.pendingTransaction)
				.success(function() {
					var transaction = $scope.pendingTransaction;
					$scope.pendingTransaction = null;
					transaction.amount = money.parse(transaction.amount);
					transaction.transaction_id = transaction.aggregate_id;
					delete transaction.aggregate_id;
					$scope.approvedTransactions.unshift(transaction);
					var originalTransaction = jQuery.grep($scope.transactions, function(t) {
						return t.aggregate_id == transaction.transaction_id;
					})[0];
					var originalIndex = $scope.transactions.indexOf(originalTransaction);
					$scope.transactions.splice(originalIndex, 1);
					$scope.$emit('pending-transactions-changed');
				});
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
		
		// $scope.startReview(transactions[0]);
	}]);
}();