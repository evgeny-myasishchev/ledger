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
			$scope.pendingTransaction.type_id = parseInt($scope.pendingTransaction.type_id);
			if(!$scope.pendingTransaction.tag_ids) $scope.pendingTransaction.tag_ids = [];
			
			if($scope.pendingTransaction.account == null) throw new Error('Account should be specified');
			
			var commandData = jQuery.extend({
				account_id: $scope.pendingTransaction.account.aggregate_id
			}, $scope.pendingTransaction);
			delete(commandData.account);
			
			$http.post('pending-transactions/' + $scope.pendingTransaction.transaction_id + '/adjust-and-approve', commandData)
				.success(function() {
					$scope.pendingTransaction = null;
					commandData.amount = money.parse(commandData.amount);
					$scope.approvedTransactions.unshift(commandData);
					removePendingTransaction(commandData.transaction_id);
					transactions.processApprovedTransaction(commandData);
					$scope.$emit('pending-transactions-changed');
				});
		};
		
		$scope.startReview = function(transaction) {
			var account = transaction.account_id == null ? null : accounts.getById(transaction.account_id);
			$scope.pendingTransaction = {
				transaction_id: transaction.transaction_id,
				amount: transaction.amount,
				date: transaction.date,
				tag_ids: transaction.tag_ids,
				comment: transaction.comment,
				account: account,
				type_id: transaction.type_id
			};
		};
		
		$scope.stopReview = function() {
			$scope.pendingTransaction = null;
		};
		
		var removePendingTransaction = function(transaction_id) {
			var transaction = jQuery.grep($scope.transactions, function(t) {
				return t.transaction_id == transaction_id;
			})[0];
			var index = $scope.transactions.indexOf(transaction);
			$scope.transactions.splice(index, 1);
		};
		
		// $scope.startReview(transactions[0]);
	}]);
}();