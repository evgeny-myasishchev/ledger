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
		this.$get = ['$routeParams', '$location', '$rootScope', 'ledgers', 'money', 'units', 
		function($routeParams, $location, $rootScope, ledgers, money, units) {
			return {
				getAll: function() {
					return accounts;
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
					account.category_id = null;
					accounts.push(account);
					$rootScope.$broadcast('account-added', account);
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
				},
				getActualBalance: function(account, rates) {
					var activeLedger = ledgers.getActiveLedger();
					var balance = account.balance;
					if(account.unit != account.currency.unit) {
						balance = units.convert(account.unit, account.currency.unit, account.balance);
					}
					if(activeLedger.currency_code == account.currency_code) {
						return balance;
					} else {
						var rate = rates[account.currency_code];
						if(rate) {
							return money.toIntegerMoney((money.toNumber(balance) * rate.rate));
						}
					}
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
			else if($location.$$path.indexOf('/accounts/') == 0) return account;
			accounts.makeActive(account);
			return account;
		}
	}]);
	
	homeApp.filter('calculateTotal', ['ledgers', 'accounts', 'money', function(ledgers, accountsService, money) {
		return function(accounts, resultExpression) {
			var that = this;
			ledgers.loadCurrencyRates().then(function(rates) {
				var result = 0;
				var activeLedger = ledgers.getActiveLedger();
				$.each(accounts, function(index, account) {
					var actualBalance = accountsService.getActualBalance(account, rates);
					if(actualBalance) result += actualBalance;
				});
				that.$eval(resultExpression + '=' + result);
			});
			return accounts;
		}
	}]);
	
	homeApp.controller('NewAccountController', ['$scope', '$http', 'money', 'ledgers', 'accounts', 
	function($scope, $http, money, ledgers, accounts) {
		var resetNewAccount = function() {
			$scope.newAccount = {
				name: null,
				currency: null,
				initialBalance: '0',
				unit: null
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
			
			//For testing
			// $scope.newAccount.currency = data.currencies[174];
		});
		
		$scope.$watch('newAccount.currency.unit', function(newVal) {
			if(newVal == 'oz') $scope.newAccount.unit = 'oz';
			else $scope.newAccount.unit = null;
		});
		
		$scope.created = false;
		$scope.creating = false;
		$scope.create = function() {
			$scope.creating = true;
			var commandData = {
				account_id: $scope.newAccount.newAccountId,
				name: $scope.newAccount.name,
				currency_code: $scope.newAccount.currency.code,
				initial_balance: $scope.newAccount.initialBalance
			};
			if($scope.newAccount.unit) commandData.unit = $scope.newAccount.unit;
			$http.post('ledgers/' + activeLedger.aggregate_id + '/accounts', commandData).success(function() {
				var account = {
					aggregate_id: commandData.account_id,
					name: commandData.name,
					currency_code: commandData.currency_code,
					currency: $scope.newAccount.currency,
					balance: money.parse(commandData.initial_balance),
					is_closed: false
				};
				if(commandData.unit) account.unit = commandData.unit;
				accounts.add(account);
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