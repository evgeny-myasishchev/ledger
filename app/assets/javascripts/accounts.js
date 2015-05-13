var accountsApp = (function($) {
	var accountsApp = angular.module('accountsApp', ['ErrorHandler', 'ngRoute', 'ledgersProvider', 'ledgerHelpers']);
	accountsApp.config(['$routeProvider', function($routeProvider) {
			$routeProvider.when('/accounts/:accountSequentialNumber/report', {
				templateUrl: "report.html",
				controller: 'ReportTransactionsController'
			});
		}
	]);
	
	accountsApp.provider('accounts', function() {
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
				getAllOpen: function() {
					return $.grep(accounts || [], function(account) { 
						return !account.is_closed;
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
				getById: function(accountId) {
					var result = $.grep(accounts, function(account) { 
						return account.aggregate_id == accountId;
					});
					if(result.length == 0) throw 'Unknown account id=' + accountId;
					if(result.length > 1) throw 'Several accounts with the same id=' + accountId + ' found. This should never happen.';
					return result[0];
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
	
	accountsApp.provider('accountsState', function() {
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
	
	accountsApp.directive('selectAccount', ['accounts', function(accounts) {
		return {
			restrict: 'E',
			replace: true,
			template: 
					"<select ng-options='account | nameWithBalance for account in accounts | filter:filterAccount | orderBy:\"name\"' " + 
						"class='form-control' required>" + 
					"</select>",
			scope: {
				account: '=ngModel',
				except: '='
			},
			link: function(scope, element, attrs) {
				scope.accounts = accounts.getAll();
				var exceptMap = {};
				if(scope.except) {
					if($.isArray(scope.except)) {
						$.each(scope.except, function(i, account) {
							exceptMap[account.aggregate_id] = true;
						})
					} else {
						exceptMap[scope.except.aggregate_id] = true;
					}
				}
				scope.filterAccount = function(account) {
					return !exceptMap[account.aggregate_id] && !account.is_closed;
				}
			}
		}
	}]);
	
	accountsApp.directive('accountsPanel', ['accounts', 'accountsState', function(accounts, accountsState) {
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
	
	accountsApp.filter('activateFirstAccount', ['accounts', '$location', function(accounts, $location) {
		return function(account) {
			var activeAccount = accounts.getActive();
			if(activeAccount) return account;
			else if($location.$$path.indexOf('/accounts/') == 0) return account;
			accounts.makeActive(account);
			return account;
		}
	}]);
	
	accountsApp.filter('calculateTotal', ['ledgers', 'accounts', 'money', function(ledgers, accountsService, money) {
		return function(accounts, scope, resultExpression) {
			var that = this;
			ledgers.loadCurrencyRates().then(function(rates) {
				var result = 0;
				var activeLedger = ledgers.getActiveLedger();
				$.each(accounts, function(index, account) {
					var actualBalance = accountsService.getActualBalance(account, rates);
					if(actualBalance) result += actualBalance;
				});
				scope.$eval(resultExpression + '=' + result);
			});
			return accounts;
		}
	}]);
	
	accountsApp.filter('nameWithBalance', ['moneyFilter', function(money) {
		return function(account) {
			return account.name + ' (' + money(account.balance) + ' ' + account.currency_code + ')';
		}
	}]);
	
	accountsApp.filter('accountById', ['accounts', function(accounts) {
		return function(accountId) {
			return accounts.getById(accountId);
		}
	}]);
	
	return accountsApp;
})(jQuery);