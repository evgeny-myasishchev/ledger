var homeApp = (function() {
	var homeApp = angular.module('homeApp', ['ErrorLogger', 'ngRoute', 'ledgerDirectives', 'ledgersProvider', 'tagsProvider']);
	
	homeApp.config(["$httpProvider", function($httpProvider) {
	  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
	}]);
	
	homeApp.controller('HomeController', ['$scope', '$http', '$location', 'tagsHelper', 'ledgers', 'accounts', 'money', 'accountsState', 'search',
	function ($scope, $http, $location, tagsHelper, ledgers, accounts, money, accountsState, search) {
		var activeAccount = $scope.activeAccount = accounts.getActive();
		
		if(activeAccount) {
			$http.get('accounts/' + activeAccount.aggregate_id + '/transactions.json').success(function(data) {
				var transactions = data.transactions;
				jQuery.each(transactions, function(i, t) {
					t.date = new Date(t.date);
				});
				$scope.transactionsInfo = {
					total: data.transactions_total,
					offset: 0,
					limit: data.transactions_limit
				};
				$scope.transactions = transactions
				activeAccount.balance = data.account_balance;
				$scope.refreshRangeState();
			});
		}
		
		$scope.renameAccount = function(account, newName) {
			return $http.put('accounts/' + account.aggregate_id + '/rename', {
				name: newName
			}).success(function() {
				account.name = newName;
			});
		};
		
		$scope.setAccountCategory = function(account, category_id) {
			return $http.put('ledgers/' + ledgers.getActiveLedger().aggregate_id + '/accounts/' + account.aggregate_id + '/set-category', {
					category_id: category_id
				})
				.success(function() {
					account.category_id = category_id;
				});
		};
		
		$scope.closeAccount = function(account) {
			return $http.post('ledgers/' + ledgers.getActiveLedger().aggregate_id + '/accounts/' + account.aggregate_id + '/close')
				.success(function() {
					account.is_closed = true;
				});
		};
		
		$scope.reopenAccount = function(account) {
			return $http.post('ledgers/' + ledgers.getActiveLedger().aggregate_id + '/accounts/' + account.aggregate_id + '/reopen')
				.success(function() {
					account.is_closed = false;
				});
		};
		
		$scope.removeAccount = function(account) {
			return $http.delete('ledgers/' + ledgers.getActiveLedger().aggregate_id + '/accounts/' + account.aggregate_id)
				.success(function() {
					accounts.remove(account);
					$location.path('/accounts');
				});
		};
		
		$scope.refreshRangeState = function() {
			$scope.canFetchRanges = $scope.transactionsInfo.total > $scope.transactionsInfo.limit;
			$scope.canFetchNextRange = $scope.transactionsInfo.offset + $scope.transactionsInfo.limit < $scope.transactionsInfo.total;
			$scope.canFetchPrevRange = $scope.transactionsInfo.offset - $scope.transactionsInfo.limit >= 0;
			$scope.currentRangeUpperBound = $scope.transactionsInfo.offset + $scope.transactionsInfo.limit;
			if($scope.currentRangeUpperBound > $scope.transactionsInfo.total) $scope.currentRangeUpperBound = $scope.transactionsInfo.total;
		};
		
		$scope.fetchNextRange = function() {
			$scope.fetch($scope.transactionsInfo.offset + $scope.transactionsInfo.limit);
		};
		
		$scope.fetchPrevRange = function() {
			$scope.fetch($scope.transactionsInfo.offset - $scope.transactionsInfo.limit);
		};
		
		$scope.fetch = function(offset, options) {
			options = $.extend({
				updateTotal: false
			}, options);
			var to = offset + $scope.transactionsInfo.limit;
			var data = {
				criteria: $scope.searchCriteria.criteria
			};
			if(options.updateTotal) data['with-total'] = true;
			$http.post('accounts/' + activeAccount.aggregate_id + '/transactions/' + offset + '-' + to + '.json', data).success(function(data) {
				var transactions = data['transactions'];
				jQuery.each(transactions, function(i, t) {
					t.date = new Date(t.date);
				});
				$scope.transactions = transactions
				$scope.transactionsInfo.offset = offset;
				if(options.updateTotal) $scope.transactionsInfo.total = data['transactions_total'];
				$scope.refreshRangeState();
			});
		};
		
		$scope.searchCriteria = {
			expression: null,
			criteria: null
		};
		
		$scope.search = function() {
			if($scope.searchCriteria.expression) {
				$scope.searchCriteria.criteria = search.parseExpression($scope.searchCriteria.expression);
			} else {
				$scope.searchCriteria.criteria = null;
			}
			$scope.fetch(0, {updateTotal: true});
		};
		
		$scope.adjustAmount = function(transaction, amount) {
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
		
		$scope.adjustTags = function(transaction, tag_ids) {
			return $http.post('transactions/' + transaction.transaction_id + '/adjust-tags', {
				command: {tag_ids: tag_ids}
			}).success(function() {
				transaction.tag_ids = tagsHelper.arrayToBracedString(tag_ids);
			});
		};
		
		$scope.adjustDate = function(transaction, date) {
			var jsonDate = date.toJSON();
			return $http.post('transactions/' + transaction.transaction_id + '/adjust-date', {
				command: {date: date.toJSON()}
			}).success(function() {
				transaction.date = date;
			});
		};
		
		$scope.adjustComment = function(transaction, comment) {
			return $http.post('transactions/' + transaction.transaction_id + '/adjust-comment', {
				command: {comment: comment}
			}).success(function() {
				transaction.comment = comment;
			});
		};
		
		$scope.removeTransaction = function(transaction) {
			return $http.delete('transactions/' + transaction.transaction_id).success(function() {
				$scope.transactions.splice($scope.transactions.indexOf(transaction), 1);
				if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
					activeAccount.balance -= transaction.amount;
				} else if (transaction.type_id == Transaction.expenceId) {
					activeAccount.balance += transaction.amount;
				}
			});
		};
		
		$scope.getTransactionTypeIcon = function(transaction) {
			if(transaction.is_transfer) return 'glyphicon-transfer';
			if(transaction.type_id == 1) return 'glyphicon-plus';
			if(transaction.type_id == 2) return 'glyphicon-minus';
			if(transaction.type_id == 3) return 'glyphicon-share-alt';
		};
		
		$scope.getTransferAmountSign = function(transaction) {
			if(transaction.is_transfer) {
				return transaction.type_id == 2 ? '-' : '+';
			} else {
				return null;
			}
		};
	}]);
	
	homeApp.filter('tti', function() {
		return function(t) {
			if(t.is_transfer || t.type == Transaction.transferKey) return 'glyphicon glyphicon-transfer';
			if(t.type_id == 1 || t.type == Transaction.incomeKey) return 'glyphicon glyphicon-plus';
			if(t.type_id == 2 || t.type == Transaction.expenceKey) return 'glyphicon glyphicon-minus';
			if(t.type_id == 3 || t.type == Transaction.refundKey) return 'glyphicon glyphicon-share-alt';
			return null;
		}
	});

	homeApp.config(['$routeProvider', function($routeProvider) {
			$routeProvider.when('/tags', {
				templateUrl: "tags.html",
				controller: 'TagsController'
			})
			.when('/categories', {
				templateUrl: "categories.html",
				controller: 'CategoriesController'
			})
			.when('/accounts', {
				templateUrl: "accounts.html",
				controller: 'HomeController'
			}).when('/accounts/new', {
				templateUrl: "new_account.html",
				controller: 'NewAccountController'
			})
			.when('/accounts/:accountSequentialNumber', {
				templateUrl: "accounts.html",
				controller: 'HomeController'
			}).when('/accounts/:accountSequentialNumber/report', {
				templateUrl: "report.html",
				controller: 'ReportTransactionsController'
			}).otherwise({
				redirectTo: '/accounts'
			});
		}
	]);
	
	return homeApp;
})();