var homeApp = (function() {
	var homeApp = angular.module('homeApp', ['ErrorLogger', 'ngRoute']);

	homeApp.controller('AccountsController', function ($scope, $http, $routeParams, accounts) {
		$scope.accounts = accounts;
		$scope.activeAccount = null;
		$scope.$watch('activeAccount', function (oldVal, newVal) {
			$http.get('accounts/' + newVal.aggregate_id + '/transactions.json').success(function(data) {
				$scope.transactions = data;
			});
		});
		
		if($routeParams.accountSequentialNumber) {
			$scope.activeAccount = jQuery.grep(accounts, function(a) { return a.sequential_number == $routeParams.accountSequentialNumber;})[0];
		} else {
			$scope.activeAccount = accounts[0];
		}
	});

	homeApp.controller('ReportTransactionsController', function ($scope, $http, $routeParams, accounts) {
		$scope.reportData = "Hello from report controller";
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