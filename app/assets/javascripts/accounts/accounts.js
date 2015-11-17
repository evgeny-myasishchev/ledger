var accountsApp = (function($) {
	var accountsApp = angular.module('accountsApp', ['ErrorHandler', 'ngRoute', 'ledgersProvider', 'ledgerHelpers']);
	accountsApp.config(['$routeProvider', function($routeProvider) {
			$routeProvider.when('/accounts/:accountSequentialNumber/report', {
				templateUrl: "report.html",
				controller: 'ReportTransactionsController'
			});
		}
	]);
	
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
	
	accountsApp.directive('actualBalanceTip', ['ledgers', 'accounts', 'money', function(ledgers, accounts, money) {
		return {
			restring: 'A',
			link: function(scope, element, attrs) {
				var that = this;
				var account = scope.account;
				var ledger = ledgers.getActiveLedger();
				if(account.currency_code != ledger.currency_code && account.currency_code != 'XXX') {
					ledgers.loadCurrencyRates().then(function(rates) {
						var integerActualAmount = accounts.getActualBalance(account, rates);
						var actualAmount = money.formatInteger(integerActualAmount);
						var rate = rates[account.currency_code].rate;
						var title = [actualAmount, ' ', ledger.currency_code, ' (1'];
						if(account.unit) {
							rate = Math.round(integerActualAmount / account.balance * 10000) / 10000;
							title.push(account.unit);
							title.push('.');
						}
						title.splice(title.length, 0, ' ', account.currency_code, ' = ', rate, ' ', ledger.currency_code, ')');
						element.attr('title', title.join(''));
					});
				}
			}
		};
	}]);
	
	return accountsApp;
})(jQuery);