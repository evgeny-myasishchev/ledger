!function() {
	var transactionsApp = angular.module('transactionsApp');
	
	transactionsApp.controller('PendingTransactionsController', ['$scope', '$http', 'accounts', 'money', 'transactions',
	function ($scope, $http, accounts, money, transactions) {
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
			$http.post('pending-transactions/' + $scope.pendingTransaction.transaction_id + '/adjust-and-approve', $scope.pendingTransaction)
				.success(function() {
					var transaction = $scope.pendingTransaction;
					$scope.pendingTransaction = null;
					transaction.amount = money.parse(transaction.amount);
					$scope.approvedTransactions.unshift(transaction);
					var originalIndex = $scope.transactions.indexOf(transaction);
					$scope.transactions.splice(originalIndex, 1);
					transactions.processApprovedTransaction(transaction);
					$scope.$emit('pending-transactions-changed');
				});
		};
		
		$scope.startReview = function(transaction) {
			$scope.pendingTransaction = {
				transaction_id: transaction.transaction_id,
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