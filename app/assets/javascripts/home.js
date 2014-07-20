var homeApp = (function() {
	var homeApp = angular.module('homeApp', ['ErrorLogger', 'ngRoute']);
	
	homeApp.config(["$httpProvider", function($httpProvider) {
	  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
	}]);
	
	homeApp.directive('bsDatepicker', function() {
		return {
			require: '?ngModel',
			link: function(scope, element, attrs, ngModel) {
				var datePicker;
				ngModel.$render = function() {
					datePicker = element.datepicker().data('datepicker');
					datePicker.setDate(ngModel.$viewValue);
				};
				element.on('change', function() {
					ngModel.$setViewValue(datePicker.getDate());
				});
			}
		}
	});

	homeApp.directive('ledgerTags', ['tags', function(tags) {
		var tagsById = {};
		jQuery.each(tags, function(index, tag) {
			tagsById['{' + tag.tag_id + '}'] = tag.name;
		});
		return {
			restrict: 'E',
			require: '?ngModel',
			link: function(scope, element, attrs, ngModel) {
				ngModel.$render = function() {
					var tagIds = ngModel.$viewValue.split(',');
					var result = [];
					jQuery.each(tagIds, function(index, tagId) {
						var tagName = tagsById[tagId];
						if(tagName) result.push(tagName);
					});
					element.html(result.join(', '));
				};
			}
		}
	}]);

	homeApp.directive('bsTagsinput', ['tags', function(tags) {
		var $ = jQuery;
		var tagsByName = {};
		$.each(tags, function(index, tag) {
			tagsByName[tag.name.toLowerCase()] = tag;
		});
		return {
			restrict: 'E',
			require: '?ngModel',
			link: function(scope, element, attrs, ngModel) {
				ngModel.$render = function() {
					var input = $('<input type="text" class="form-control" placeholder="Tags" style="width: 100%">').appendTo(element);
					input.tagsinput({
						confirmKeys: [188],
						tagClass: function(tag) {
							return tagsByName[tag.toLowerCase()] ? 'label label-info' : 'label label-warning';
						}
					});
					input.on('change', function() {
						var selectedTagNames = input.tagsinput('items');
						if(selectedTagNames.length) {
							input.tagsinput('input').removeAttr('placeholder');
						} else {
							input.tagsinput('input').attr('placeholder', 'Tags');
						}
						var tagIds = [];
						$.each(selectedTagNames, function(index, tagName) {
							var tag = tagsByName[tagName.toLowerCase()];
							if(tag) tagIds.push(tag.tag_id);
						});
						ngModel.$setViewValue(tagIds, 'change');
					});
				};
			}
		}
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
	});

	homeApp.controller('ReportTransactionsController', function ($scope, $http, activeAccountResolver, tags) {
		var activeAccount = $scope.account = activeAccountResolver.resolve();
		$scope.reportedTransactions = [];
		//For testing purposes
		// $scope.reportedTransactions = [
		// 	{"type":"income","ammount":90,"tag_ids":[1, 2],"comment":"test123123","date":new Date("2014-07-16T21:09:27.000Z")},
		// 	{"type":"expence","ammount":2010,"tag_ids":[2],"comment":null,"date":new Date("2014-07-16T21:09:06.000Z")},
		// 	{"type":"expence","ammount":1050,"tag_ids":[2,3],"comment":"Having lunch and getting some food","date":new Date("2014-07-16T21:08:51.000Z")},
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