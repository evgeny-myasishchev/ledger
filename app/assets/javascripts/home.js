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
		var createTagsMatcher = function(theTags) {
			console.log('Creating the matcher...');
			return function findMatches(q, cb) {
				console.log('Finding matches...');
				var matches = [], substrRegex = new RegExp(q, 'i');
				$.each(theTags, function(i, tag) {
					if (substrRegex.test(tag.name)) {
						matches.push({ value: tag.name });
					}
				});
				cb(matches);
			};
		};


		return {
			restrict: 'A',
			require: '?ngModel',
			link: function(scope, element, attrs, ngModel) {
				var element = jQuery(element);
				ngModel.$render = function() {
					element.tagsinput();
					element.tagsinput('input').typeahead({
						hint: true,
						highlight: true,
						minLength: 1
					},
					{
						name: 'tags',
						displayKey: 'value',
						source: createTagsMatcher(tags)
					}).on('typeahead:selected', function(e, s, ds) {
						console.log(e);
						console.log(s);
						console.log(ds);
					}).on('typeahead:autocompleted', function(e, s, ds) {
						console.log(e);
						console.log(s);
						console.log(ds);
					});
				};
			}
		}
	}]);
	

	homeApp.directive('bsTagsinput1', [function() {
		var substringMatcher = function(strs) {
			return function findMatches(q, cb) {
				var matches, substrRegex;
 
				// an array that will be populated with substring matches
				matches = [];
 
				// regex used to determine if a string contains the substring `q`
				substrRegex = new RegExp(q, 'i');
 
				// iterate through the pool of strings and for any string that
				// contains the substring `q`, add it to the `matches` array
				$.each(strs, function(i, str) {
					if (substrRegex.test(str)) {
						// the typeahead jQuery plugin expects suggestions to a
						// JavaScript object, refer to typeahead docs for more info
						matches.push({ value: str });
					}
				});
 
				cb(matches);
			};
		};
 
		var states = ['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California',
		'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii',
		'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
		'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
		'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire',
		'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota',
		'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
		'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
		'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming'
		];
		
		return {
			restrict: 'A',
			require: '?ngModel',
			link: function(scope, element, attrs, ngModel) {
				ngModel.$render = function() {
					element.typeahead({
						hint: true,
						highlight: true,
						minLength: 1
					},
					{
						name: 'states',
						displayKey: 'value',
						source: substringMatcher(states)
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
		$scope.availableTags = jQuery.map(tags, function(tag) {
			return {value: tag.tag_id, text: tag.name}
		});
		$scope.getTags = function() {
			return $scope.tags;
		};
		
		//For testing purposes
		// $scope.reportedTransactions = [
		// 	{"type":"income","ammount":90,"tags":['food'],"comment":"test123123","date":new Date("2014-07-16T21:09:27.000Z")},
		// 	{"type":"expence","ammount":2010,"tags":['lunch'],"comment":null,"date":new Date("2014-07-16T21:09:06.000Z")},
		// 	{"type":"expence","ammount":1050,"tags":['lunch', 'food'],"comment":"Having lunch and getting some food","date":new Date("2014-07-16T21:08:51.000Z")},
		// 	{"type":"expence","ammount":1050,"tags":null,"comment":"test1","date":new Date("2014-07-16T21:08:44.000Z")},
		// 	{"type":"expence","ammount":1050,"tags":null,"comment":null,"date":new Date("2014-06-30T21:00:00.000Z")}
		// ];
		
		var addReportedTransaction = function(transaction) {
			$scope.reportedTransactions.push(transaction);
		};
		
		var resetNewTransaction = function() {
			$scope.newTransaction = {
				ammount: null,
				tags: [],
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
					tags: $scope.newTransaction.tags,
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