var homeApp = (function() {
	var homeApp = angular.module('homeApp', ['ErrorLogger', 'ngRoute', 'ledgerDirectives']);
	
	homeApp.config(["$httpProvider", function($httpProvider) {
	  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
	}]);

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
		
		$scope.getTransactionTypeIcon = function(transaction) {
			if(transaction.is_transfer) return 'glyphicon-transfer';
			if(transaction.type_id == 1) return 'glyphicon-plus';
			if(transaction.type_id == 2) return 'glyphicon-minus';
			if(transaction.type_id == 3) return 'glyphicon-share-alt';
		};
	});

	homeApp.controller('ReportTransactionsController', function ($scope, $http, activeAccountResolver, tags) {
		var activeAccount = $scope.account = activeAccountResolver.resolve();
		$scope.reportedTransactions = [];
		//For testing purposes
		// $scope.reportedTransactions = [
		// 	{"type":"income","ammount":90,"tag_ids":'{1},{2}',"comment":"test123123","date":new Date("2014-07-16T21:09:27.000Z")},
		// 	{"type":"expence","ammount":2010,"tag_ids":'{2}',"comment":null,"date":new Date("2014-07-16T21:09:06.000Z")},
		// 	{"type":"expence","ammount":1050,"tag_ids":'{2},{3}',"comment":"Having lunch and getting some food","date":new Date("2014-07-16T21:08:51.000Z")},
		// 	{"type":"expence","ammount":1050,"tag_ids":null,"comment":"test1","date":new Date("2014-07-16T21:08:44.000Z")},
		// 	{"type":"expence","ammount":1050,"tag_ids":null,"comment":null,"date":new Date("2014-06-30T21:00:00.000Z")}
		// ];
		
		var addReportedTransaction = function(transaction) {
			transaction.tag_ids = jQuery.map(transaction.tag_ids, function(tag_id) {
				return '{' + tag_id + '}';
			}).join(',');
			$scope.reportedTransactions.push(transaction);
		};
		
		var resetNewTransaction = function() {
			$scope.newTransaction = {
				ammount: null,
				tag_ids: [],
				type: 'expence',
				date: new Date(),
				comment: null
			};
		};
		resetNewTransaction();
		$scope.report = function() {
			$http.post('accounts/' + activeAccount.aggregate_id + '/transactions/report-' + $scope.newTransaction.type, {
				command: {
					ammount: $scope.newTransaction.ammount,
					tag_ids: $scope.newTransaction.tag_ids,
					date: $scope.newTransaction.date.toJSON(),
					comment: $scope.newTransaction.comment
				}
			}).success(function() {
				addReportedTransaction($scope.newTransaction);
				resetNewTransaction();
			});
		};
		
		$scope.formatTagNames = function(tags) {
			if(tags && tags.length) {
				return '{' + tags.join(',') + '}, ';
			};
			return '';
		};
		
		$scope.formatDate = function(date) {
			if(tags && tags.length) {
				return tags.join(',') + ', ';
			};
			return '';
		};
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