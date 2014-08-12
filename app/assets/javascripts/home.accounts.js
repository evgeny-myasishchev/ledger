!function($) {
	var homeApp = angular.module('homeApp');
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
					balance: money.parse($scope.newAccount.initialBalance)
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