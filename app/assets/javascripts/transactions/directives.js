!function($) {
	var transactionsApp = angular.module('transactionsApp');
	
	transactionsApp.directive('showTransactionInfo', 
	['$templateCache', '$compile', 'accounts', 'transactions', function($templateCache, $compile, accounts, transactions) {
		var template = $templateCache.get('transfer-transaction-info.html');
		var transferInfoLink = $compile(template);
		var handleTransferTransaction = function(scope, element) {
			element.mouseenter(function() {
				element.tooltip({
					html: true, 
					trigger: 'manual',
					container: 'body',
					title: function() {
						var linked = transferInfoLink(scope, function() {});
						scope.$digest();
						return linked;
					}
				});
				element.on('hidden.bs.tooltip', function(e) {
					element.tooltip('destroy');
				});
				element.tooltip('show');
			});
			element.mouseleave(function() {
				element.tooltip('destroy');
			})
			scope.$on('$destroy', function() {
				element.tooltip('destroy');
			});
		}
		
		return {
			restrict: 'A',
			template: '',
			link: function(scope, element, attrs) {
				if(scope.transaction.is_transfer) {
					handleTransferTransaction(scope, element);
				}
			}
		}
	}]);

	
	transactionsApp.directive('moveTransactionAction', 
	['$templateCache', '$compile', 'accounts', 'transactions', function($templateCache, $compile, accounts, transactions) {
		var template = $templateCache.get('move-transaction.html');
		var link = $compile(template);
		return {
			restrict: 'A',
			template: '',
			scope: {
				transaction: '='
			},
			link: function(scope, element, attrs) {
				var popoverParent;
				scope.move = function() {
					transactions.moveTo(scope.transaction, scope.targetAccount).then(function() {
						if(popoverParent) popoverParent.popover('hide');
					});
				}
				scope.cancel = function() {
					if(popoverParent) {
						popoverParent.popover('hide');
					}
				}
				element.click(function(e) {
					scope.accounts = accounts.getAllOpen();
					scope.targetAccount = null;
					if(scope.transaction.is_transfer) {
						scope.dontMoveTo = [
							accounts.getById(scope.transaction.sending_account_id),
							accounts.getById(scope.transaction.receiving_account_id)
						];
					} else {
						scope.dontMoveTo = accounts.getById(scope.transaction.account_id);
					}
					popoverParent = $(element).parents('.btn-group');
					popoverParent.popover({
						html: true, 
						title: 'Moving transaction',
						trigger: 'manual',
						placement: 'left',
						content: function() {
							return link(scope, function() {});
						}
					});
					popoverParent.data('bs.popover').tip()
						.css('min-width', 300).css('max-width', 500);
					popoverParent.on('hidden.bs.popover', function(e) {
						popoverParent.popover('destroy');
					});
					popoverParent.popover('show');
				});
				scope.$on('$destroy', function() {
					if(popoverParent) popoverParent.popover('destroy');
				});
				// if(scope.transaction.transaction_id == 'a571a773-8df0-4d1a-a254-1ae3706894b4')
				// 	setTimeout(function() { element.trigger('click'); }, 100);
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
						comment: comment
					}).success(function() {
						transaction.comment = comment;
					});
				};
				
				scope.adjustTags = function(transaction, tag_ids) {
					return $http.post('transactions/' + transaction.transaction_id + '/adjust-tags', {
						tag_ids: tag_ids
					}).success(function() {
						transaction.tag_ids = tagsHelper.arrayToBracedString(tag_ids);
					});
				};
		
				scope.adjustDate = function(transaction, date) {
					var jsonDate = date.toJSON();
					return $http.post('transactions/' + transaction.transaction_id + '/adjust-date', {
						date: date.toJSON()
					}).success(function() {
						transaction.date = date;
					});
				};
				
				scope.adjustAmount = function(transaction, amount) {
					amount = money.parse(amount);
					return $http.post('transactions/'+ transaction.transaction_id + '/adjust-amount', {
						amount: amount
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