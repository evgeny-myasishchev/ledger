ledgerApp.controller('HomeController', function ($scope, accounts) {
	$scope.accounts = accounts;
	$scope.selectAccount = function(account) {
		$scope.activeAccount = account;
	};
	$scope.isActive = function(account) {
		return $scope.activeAccount == account;
	};
});