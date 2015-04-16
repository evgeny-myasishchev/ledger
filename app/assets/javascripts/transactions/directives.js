!function($) {
	var transactionsApp = angular.module('transactionsApp');
	
	transactionsApp.directive('moveTransactionAction', 
	['$templateCache', '$compile', 'accounts', 'transactions', function($templateCache, $compile, accounts, transactions) {
		var template = $templateCache.get('move-transaction.html');
		var link = $compile(template);
		return {
			restrict: 'A',
			template: '',
			link: function(scope, element, attrs) {
				var popoverParent;
				scope.move = function() {
					transactions.moveTo(scope.transaction, scope.targetAccount).then(function() {
						popoverParent.popover('hide');
					});
				}
				scope.cancel = function() {
					popoverParent.popover('hide');
				}
				element.click(function(e) {
					if(!popoverParent) {
						if(!scope.accounts) scope.accounts = accounts.getAllOpen();
						popoverParent = $(element).parents('.btn-group');
						console.log(popoverParent);
					}
					popoverParent.popover({
						html: true, 
						title: 'Moving transaction',
						trigger: 'manual',
						placement: 'left',
						container: 'body',
						content: function() { return link(scope); }
					});
					popoverParent.on('hidden.bs.popover', function() {
						popoverParent.popover('destroy');
					});
					popoverParent.popover('show');
				});
				
				scope.$on('$destroy', function() {
					if(popoverParent) popoverParent.popover('destroy');
				});
				// if(scope.transaction.transaction_id == '13355f56-3542-4017-80ca-0f3ea49a383e')
				// 	element.trigger('click');
			}
		}
	}]);

	transactionsApp.directive('transactionsList', ['$http', 'accounts', 'tagsHelper', 'money', function($http, accounts, tagsHelper, money) {
		return {
			restrict: 'E',
			templateUrl: 'transactions-list.html',
			scope: {
				showAccount: '=',
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
	
	transactionsApp.directive('pendingTransactionsMenuInjector', ['transactions', function(transactions) {
		var updateActionState = function(scope, element) {
			scope.count = transactions.getPendingCount();
			if(scope.count > 0) element.show();
			else element.hide();
		};
		return {
			restrict: 'E',
			replace: true,
			templateUrl: 'pending-transactions-menu.html',
			scope: {},
			link: function(scope, element, attrs) {
				angular.element('#main-navbar-right').prepend(element);
				scope.$root.$on('pending-transactions-changed', function() {
					updateActionState(scope, element);
				});
				updateActionState(scope, element);
			}
		}
	}]);
	
	transactionsApp.directive('reviewAndApprovePending', [function() {
		return {
			restrict: 'E',
			replace: true,
			templateUrl: 'review-and-approve-pending-transaction.html',
			link: function(scope, element, attrs) {
				element.modal({
					show: false
				});
				element.on('shown.bs.modal', function() {
					element.find('select:first').focus();
				});
				
				scope.$watch('pendingTransaction', function(newVal) {
					if(newVal) {
						element.modal('show');
					} else {
						element.modal('hide');
					}
				});
			}
		}
	}]);
	
}(jQuery);