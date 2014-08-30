!function($) {
	var homeApp = angular.module('homeApp');
	
	homeApp.provider('accounts', function() {
		var accounts, categories;
		this.assignAccounts = function(value) {
			accounts = value;
		};
		this.assignCategories = function(value) {
			categories = value;
		};
		var getActiveAccountFromRoute = function(sequential_number) {
			return jQuery.grep(accounts, function(a) { return a.sequential_number == sequential_number; })[0];
		};
		this.$get = ['$routeParams', '$location', function($routeParams, $location) {
			return {
				getAll: function() {
					return accounts;
				},
				getUncategorisedAccounts: function() {
					return $.grep(accounts, function(account) {
						return account.category_id == null;
					});
				},
				getAllCategories: function() {
					return categories;
				},
				getActive: function() {
					var activeAccount = null;
					if($routeParams.accountSequentialNumber) {
						activeAccount = getActiveAccountFromRoute($routeParams.accountSequentialNumber);
					}
					return activeAccount;
				},
				makeActive: function(account) {
					$location.path('/accounts/' + account.sequential_number);
				},
				add: function(account) {
					var lastSequentialNumber = 0;
					$.each(accounts, function(index, account) {
						if(account.sequential_number > lastSequentialNumber) lastSequentialNumber = account.sequential_number;
					});
					account.sequential_number = lastSequentialNumber + 1;
					accounts.push(account);
					return account;
				},
				remove: function(account) {
					var index = accounts.indexOf(account);
					accounts.splice(index, 1);
				},
				addCategory: function(category_id, name) {
					var lastDisplayOrder = 0;
					$.each(categories, function(index, category) {
						if(category.display_order > lastDisplayOrder) lastDisplayOrder = category.display_order;
					});
					categories.push({category_id: category_id, display_order: lastDisplayOrder + 1, name: name});
				},
				removeCategory: function(category) {
					var index = categories.indexOf(category);
					categories.splice(index, 1);
				}
			}
		}];
	});
	
	homeApp.provider('accountsState', function() {
		var showingClosed = false;
		this.$get = function() {
			return {
				showingClosed: function(value) {
					if(typeof(value) != 'undefined') showingClosed = value;
					return showingClosed;
				}
			}
		}
	});
	
	homeApp.directive('accountsPanel', ['accounts', 'accountsState', function(accounts, accountsState) {
		return {
			restrict: 'E',
			templateUrl: 'accounts-panel.html',
			link: function(scope, element, attrs) {
				scope.accounts = accounts.getAll();
				scope.uncategorised = accounts.getUncategorisedAccounts();
				scope.categories = accounts.getAllCategories();
				
				scope.showClosed = accountsState.showingClosed();
				scope.hasClosedAccounts = function() {
					for(var i = 0; i < scope.accounts.length; i++) {
						if(scope.accounts[i].is_closed) {
							return true;
						}
					}
					return false;
				};
				scope.toggleShowClosedAccounts = function() {
					scope.showClosed = accountsState.showingClosed(!scope.showClosed);
				};
			}
		}
	}]);
	
	homeApp.filter('activateFirstAccount', ['accounts', '$location', function(accounts, $location) {
		return function(account) {
			var activeAccount = accounts.getActive();
			if(activeAccount) return account;
			else if($location.$$path.startsWith('/accounts/')) return account;
			accounts.makeActive(account);
			return account;
		}
	}]);
	
	homeApp.controller('NewAccountController', ['$scope', '$http', 'money', 'ledgers', 'accounts', 
	function($scope, $http, money, ledgers, accounts) {
		var resetNewAccount = function() {
			$scope.newAccount = {
				name: null,
				currencyCode: null,
				initialBalance: '0'
			};
		}
		resetNewAccount();
		
		//For testing
		// $scope.newAccount.name = 'New account 123';
		// $scope.newAccount.currencyCode = 'UAH';
		// $scope.newAccount.initialBalance = '100.93';
		
		$scope.currencies = [];
		var activeLedger = ledgers.getActiveLedger();
		$http.get('ledgers/' + activeLedger.aggregate_id + '/accounts/new.json').success(function(data) {
			$scope.newAccount.newAccountId = data.new_account_id;
			$scope.currencies = data.currencies;
		});
		
		$scope.created = false;
		$scope.creating = false;
		$scope.create = function() {
			$scope.creating = true;
			$http.post('ledgers/' + activeLedger.aggregate_id + '/accounts', {
				account_id: $scope.newAccount.newAccountId,
				name: $scope.newAccount.name,
				currency_code: $scope.newAccount.currencyCode,
				initial_balance: $scope.newAccount.initialBalance
			}).success(function() {
				accounts.add({
					aggregate_id: $scope.newAccount.newAccountId,
					name: $scope.newAccount.name,
					currency_code: $scope.newAccount.currencyCode,
					balance: money.parse($scope.newAccount.initialBalance),
					is_closed: false
				});
				$scope.created = true;
			}).finally(function() {
				$scope.creating = false;
			});
		};
		$scope.createAnother = function() {
			$http.get('ledgers/' + activeLedger.aggregate_id + '/accounts/new.json').success(function(data) {
				resetNewAccount();
				$scope.newAccount.newAccountId = data.new_account_id;
				$scope.created = false;
			});
		};
	}]);
}(jQuery);