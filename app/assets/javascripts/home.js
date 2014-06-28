var homeApp = (function() {
	var homeApp = angular.module('homeApp', ['ErrorLogger', 'ngRoute']);

	homeApp.controller('AccountsController', function ($scope, $routeParams, accounts) {
		$scope.accounts = accounts;
		if($routeParams.accountId) {
			$scope.activeAccount = jQuery.grep(accounts, function(a) { return a.id == $routeParams.accountId;})[0];
		} else {
			$scope.activeAccount = accounts[0];
		}
	});

	homeApp.config(['$routeProvider', function($routeProvider) {
			$routeProvider.when('/accounts/:accountId', {
				templateUrl: "accounts.html",
				controller: 'AccountsController'
			});
		}
	]);
	
	return homeApp;
})();