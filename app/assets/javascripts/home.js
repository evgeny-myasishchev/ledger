var homeApp = (function() {
	var homeApp = angular.module('homeApp', ['ErrorHandler', 'ngRoute', 'ledgerDirectives', 'ledgersProvider', 'tagsProvider', 'accountsApp', 'transactionsApp']);
	
	homeApp.config(["$httpProvider", function($httpProvider) {
	  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
	}]);
	
	homeApp.controller('HomeController', ['$scope', '$http', '$location', 'tagsHelper', 
	'ledgers', 'accounts', 'money', 'accountsState', 'search',
	function ($scope, $http, $location, tagsHelper, ledgers, accounts, money, accountsState, search) {
		var activeAccount = $scope.activeAccount = accounts.getActive();
		var transactionsBasePath = activeAccount ? 'accounts/' + activeAccount.aggregate_id + '/' : '';
		$scope.accountsAvailable = accounts.getAll().length > 0;
		$scope.startRenaming = function() { $scope.isRenaming = true; };
		$scope.stopRenaming = function() { $scope.isRenaming = false; };
		
		$http.get(transactionsBasePath + 'transactions.json').success(function(data) {
			var transactions = data.transactions;
			jQuery.each(transactions, function(i, t) {
				t.date = new Date(t.date);
			});
			$scope.transactionsInfo = {
				total: data.transactions_total,
				offset: 0,
				limit: data.transactions_limit
			};
			$scope.transactions = transactions;
			if(activeAccount) activeAccount.balance = data.account_balance;
			$scope.refreshRangeState();
		});
		
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
			$http.post(transactionsBasePath + 'transactions/' + offset + '-' + to + '.json', data).success(function(data) {
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
	}]);

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
			}).otherwise({
				redirectTo: '/accounts'
			});
		}
	]);
	
	return homeApp;
})();