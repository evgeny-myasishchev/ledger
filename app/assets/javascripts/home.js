var homeApp = (function() {
	var homeApp = angular.module('homeApp', ['ErrorLogger', 'ngRoute', 'ledgerDirectives']);
	
	homeApp.config(["$httpProvider", function($httpProvider) {
	  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
	}]);

	homeApp.factory('activeAccountResolver', function(accounts, $routeParams) {
		return {
			resolve: function() {
				var activeAccount = null;

				var getActiveAccountFromRoute = function() {
					return jQuery.grep(accounts, function(a) { return a.sequential_number == $routeParams.accountSequentialNumber;})[0]
				};

				if($routeParams.accountSequentialNumber) {
					activeAccount = getActiveAccountFromRoute();
				} else {
					activeAccount = accounts[0];
				}

				return activeAccount;
			}
		};
	});

	homeApp.controller('HomeController', ['$scope', '$http', 'tagsHelper', 'accounts', 'activeAccountResolver', 'money',
	function ($scope, $http, tagsHelper, accounts, activeAccountResolver, money) {
		$scope.accounts = accounts;
		var activeAccount = $scope.activeAccount = activeAccountResolver.resolve();
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
		
		$scope.fetch = function(offset) {
			var to = offset + $scope.transactionsInfo.limit;
			$http.get('accounts/' + activeAccount.aggregate_id + '/transactions/' + offset + '-' + to + '.json').success(function(transactions) {
				jQuery.each(transactions, function(i, t) {
					t.date = new Date(t.date);
				});
				$scope.transactions = transactions
				$scope.transactionsInfo.offset = offset;
				$scope.refreshRangeState();
			});
		};
		
		$scope.adjustAmmount = function(transaction, ammount) {
			ammount = money.parse(ammount);
			return $http.post('transactions/' + transaction.transaction_id + '/adjust-ammount', {
				command: {ammount: ammount}
			}).success(function() {
				var oldAmmount = transaction.ammount;
				transaction.ammount = ammount;
				if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
					activeAccount.balance = activeAccount.balance - oldAmmount + ammount;
				} else if (transaction.type_id == Transaction.expenceId) {
					activeAccount.balance = activeAccount.balance + oldAmmount - ammount;
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
					activeAccount.balance -= transaction.ammount;
				} else if (transaction.type_id == Transaction.expenceId) {
					activeAccount.balance += transaction.ammount;
				}
			});
		};
		
		$scope.getTransactionTypeIcon = function(transaction) {
			if(transaction.is_transfer) return 'glyphicon-transfer';
			if(transaction.type_id == 1) return 'glyphicon-plus';
			if(transaction.type_id == 2) return 'glyphicon-minus';
			if(transaction.type_id == 3) return 'glyphicon-share-alt';
		};
		
		$scope.getTransferAmmountSign = function(transaction) {
			if(transaction.is_transfer) {
				return transaction.type_id == 2 ? '-' : '+';
			} else {
				return null;
			}
		};
	}]);

	homeApp.config(['$routeProvider', function($routeProvider) {
			$routeProvider.when('/accounts', {
				templateUrl: "accounts.html",
				controller: 'HomeController'
			}).when('/accounts/:accountSequentialNumber', {
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