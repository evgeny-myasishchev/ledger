!function($) {
	var transactionsApp = angular.module('transactionsApp');

	transactionsApp.directive('transactionsList', ['$http', 'accounts', 'tagsHelper', 'money', function($http, accounts, tagsHelper, money) {
		return {
			restrict: 'E',
			templateUrl: 'transactions-list.html',
			scope: {
				transactions: '=data'
			},
			link: function(scope, element, attrs) {
				if(typeof(attrs.data) == 'undefined') {
					throw 'Failed to initialize transactions list: data attribute is required.';
				}
				scope.adjustComment = function(transaction, comment) {
					return $http.post('transactions/' + transaction.transaction_id + '/adjust-comment', {
						command: {comment: comment}
					}).success(function() {
						transaction.comment = comment;
					});
				};
				
				scope.adjustTags = function(transaction, tag_ids) {
					return $http.post('transactions/' + transaction.transaction_id + '/adjust-tags', {
						command: {tag_ids: tag_ids}
					}).success(function() {
						transaction.tag_ids = tagsHelper.arrayToBracedString(tag_ids);
					});
				};
		
				scope.adjustDate = function(transaction, date) {
					var jsonDate = date.toJSON();
					return $http.post('transactions/' + transaction.transaction_id + '/adjust-date', {
						command: {date: date.toJSON()}
					}).success(function() {
						transaction.date = date;
					});
				};
				
				scope.adjustAmount = function(transaction, amount) {
					amount = money.parse(amount);
					return $http.post('transactions/'+ transaction.transaction_id + '/adjust-amount', {
						command: {amount: amount}
					}).success(function() {
						var oldAmount = transaction.amount;
						transaction.amount = amount;
						var account = accounts.getById(transaction.account_id);
						if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
							account.balance = account.balance - oldAmount + amount;
						} else if (transaction.type_id == Transaction.expenceId) {
							account.balance = account.balance + oldAmount- amount;
						}
					});
				};
				
				scope.removeTransaction = function(transaction) {
					return $http.delete('transactions/' + transaction.transaction_id).success(function() {
						scope.transactions.splice(scope.transactions.indexOf(transaction), 1);
						var account = accounts.getById(transaction.account_id);
						if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
							account.balance -= transaction.amount;
						} else if (transaction.type_id == Transaction.expenceId) {
							account.balance += transaction.amount;
						}
					});
				};
				
				scope.getTransferAmountSign = function(transaction) {
					if(transaction.is_transfer) {
						return transaction.type_id == 2 ? '-' : '+';
					} else {
						return null;
					}
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
	
	transactionsApp.directive('pendingTransactionsMenuInjector', [function() {
		return {
			restrict: 'E',
			replace: true,
			templateUrl: 'pending-transactions-menu.html',
			scope: {
				count: '=count'
			},
			link: function(scope, element, attrs) {
				if(!attrs.count) {
					return;
				}
				element.prependTo('#main-navbar-right');
			}
		}
	}]);
	
}(jQuery);