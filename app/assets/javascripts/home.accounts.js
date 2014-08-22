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
		this.$get = ['$routeParams', function($routeParams) {
			return {
				getAll: function() {
					return accounts;
				},
				getAllCategories: function() {
					return categories;
				},
				getActive: function() {
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
				}
			}
		}];
	});
	
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