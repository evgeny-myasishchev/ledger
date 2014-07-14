var homeApp = (function() {
	var homeApp = angular.module('homeApp', ['ErrorLogger', 'ngRoute']);

	homeApp.factory('activeAccountResolver', function(accounts, $routeParams) {
		return {
			resolve: function() {
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
			}
		};
	});

	homeApp.controller('AccountsController', function ($scope, $http, $routeParams, accounts, activeAccountResolver) {
		$scope.accounts = accounts;
		var activeAccount = $scope.activeAccount = activeAccountResolver.resolve();
		$http.get('accounts/' + activeAccount.aggregate_id + '/transactions.json').success(function(data) {
			$scope.transactions = data;
		});
	});

	homeApp.controller('ReportTransactionsController', function ($scope, $http, activeAccountResolver) {
		$scope.account = activeAccountResolver.resolve();
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