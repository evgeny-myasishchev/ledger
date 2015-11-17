!function($) {
	'use strict';
	
	angular.module('accountsApp')
		.controller('NewAccountController', NewAccountController);

	NewAccountController.$inject = ['$scope', '$http', 'money', 'ledgers', 'accounts'];

	function NewAccountController($scope, $http, money, ledgers, accounts) {
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
			commandData.unit = $scope.newAccount.unit;
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
	}
}(jQuery);