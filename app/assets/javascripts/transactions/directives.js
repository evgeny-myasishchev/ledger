!function() {
	var transactionsApp = angular.module('transactionsApp');

	transactionsApp.directive('transactionsList', ['$http', function() {
		return {
			restrict: 'E',
			templateUrl: 'transactions.html',
			link: function(scope, element, attrs) {
				scope.adjustAmount = function(transaction, amount) {
					amount = money.parse(amount);
					return $http.post('transactions/'+ transaction.transaction_id + '/adjust-amount', {
						command: {amount: amount}
					}).success(function() {
						var oldAmount = transaction.amount;
						transaction.amount = amount;
						if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
							activeAccount.balance = activeAccount.balance - oldAmount + amount;
						} else if (transaction.type_id == Transaction.expenceId) {
							activeAccount.balance = activeAccount.balance + oldAmount- amount;
						}
					});
				};
			}
		}
	}]);


	transactionsApp.filter('tti', function() {
		return function(t) {
			if(t.is_transfer || t.type == Transaction.transferKey) return 'glyphicon glyphicon-transfer';
			if(t.type_id == 1 || t.type == Transaction.incomeKey) return 'glyphicon glyphicon-plus';
			if(t.type_id == 2 || t.type == Transaction.expenceKey) return 'glyphicon glyphicon-minus';
			if(t.type_id == 3 || t.type == Transaction.refundKey) return 'glyphicon glyphicon-share-alt';
			return null;
		}
	});
}();