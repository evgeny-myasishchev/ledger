!function($) {
	var homeApp = angular.module('homeApp');
	homeApp.controller('NewAccountController', ['$scope', '$http', 'money', 'ledgers', 'accounts', 
	function($scope, $http, money, ledgers, accounts) {
		$scope.newAccount = {
			name: null,
			currencyCode: null,
			initialBalance: '0'
		};
		$scope.currencies = [];
		var activeLedger = ledgers.getActiveLedger();
		$http.get('ledgers/' + activeLedger.aggregate_id + '/accounts/new.json').success(function(data) {
			$scope.newAccount.newAccountId = data.new_account_id;
			$scope.currencies = data.currencies;
		});
		
		$scope.report = function() {
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
			})
		};
	}]);
}(jQuery);