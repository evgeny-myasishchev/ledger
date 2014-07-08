var homeApp = (function() {
	var homeApp = angular.module('homeApp', ['ErrorLogger', 'ngRoute']);

	homeApp.factory('activeAccountAccessor', function(accounts, $routeParams) {
		var activeAccount = null;

		var getActiveAccountFromRoute = function() {
			return jQuery.grep(accounts, function(a) { return a.sequential_number == $routeParams.accountSequentialNumber;})[0]
		};

		if($routeParams.accountSequentialNumber) {
			activeAccount = getActiveAccountFromRoute();
		} else {
			activeAccount = accounts[0];
		}
		return {
			get: function() { return activeAccount; },
			set: function(value) { activeAccount = value; }
		}
	});

	homeApp.controller('AccountsController', function ($scope, $http, $routeParams, accounts, activeAccountAccessor) {
		$scope.accounts = accounts;
		var activeAccount = $scope.activeAccount = activeAccountAccessor.get();
		$http.get('accounts/' + activeAccount.aggregate_id + '/transactions.json').success(function(data) {
			$scope.transactions = data;
		});
	});

	homeApp.controller('ReportTransactionsController', function ($scope, $http, activeAccountAccessor) {
		$scope.account = activeAccountAccessor.get();
	});

	homeApp.config(['$routeProvider', function($routeProvider) {
			$routeProvider.when('/accounts', {
				templateUrl: "accounts.html",
				controller: 'AccountsController'
			}).when('/accounts/:accountSequentialNumber', {
				templateUrl: "accounts.html",
				controller: 'AccountsController'
			}).when('/accounts/:accountSequentialNumber/report', {
				templateUrl: "report.html",
				controller: 'ReportTransactionsController'
			}).otherwise({
				redirectTo: '/accounts'
			});
		}
	]);
	
	return homeApp;
})();