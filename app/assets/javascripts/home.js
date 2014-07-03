var homeApp = (function() {
	var homeApp = angular.module('homeApp', ['ErrorLogger', 'ngRoute']);

	homeApp.controller('AccountsController', function ($scope, $http, $routeParams, accounts) {
		$scope.accounts = accounts;
		$scope.activeAccount = null;
		$scope.$watch('activeAccount', function (oldVal, newVal) {
			$http.get('accounts/' + newVal.id + '/transactions.json').success(function(data) {
				$scope.transactions = data;
			});
		});
		
		if($routeParams.accountId) {
			$scope.activeAccount = jQuery.grep(accounts, function(a) { return a.id == $routeParams.accountId;})[0];
		} else {
			$scope.activeAccount = accounts[0];
		}
	});

	homeApp.config(['$routeProvider', function($routeProvider) {
			$routeProvider.when('/accounts', {
				templateUrl: "accounts.html",
				controller: 'AccountsController'
			}).when('/accounts/:accountId', {
				templateUrl: "accounts.html",
				controller: 'AccountsController'
			}).otherwise({
				redirectTo: '/accounts'
			});
		}
	]);
	
	return homeApp;
})();