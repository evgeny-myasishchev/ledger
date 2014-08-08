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

	homeApp.controller('AccountsController', ['$scope', '$http', 'tagsHelper', 'accounts', 'activeAccountResolver', 'money',
	function ($scope, $http, tagsHelper, accounts, activeAccountResolver, money) {
		$scope.accounts = accounts;
		var activeAccount = $scope.activeAccount = activeAccountResolver.resolve();
		$http.get('accounts/' + activeAccount.aggregate_id + '/transactions.json').success(function(data) {
			var transactions = data.transactions;
			jQuery.each(transactions, function(i, t) {
				t.date = new Date(t.date);
			});
			$scope.transactionsInfo = {
				total: data.transactions_total,
				offset: 0,
				limit: data.transactions_limit
			};
			$scope.transactions = transactions
			activeAccount.balance = data.account_balance;
			$scope.refreshRangeState();
		});
		
		$scope.refreshRangeState = function() {
			$scope.canFetchRanges = $scope.transactionsInfo.total > $scope.transactionsInfo.limit;
			$scope.canFetchNextRange = $scope.transactionsInfo.offset + $scope.transactionsInfo.limit < $scope.transactionsInfo.total;
			$scope.canFetchPrevRange = $scope.transactionsInfo.offset - $scope.transactionsInfo.limit >= 0;
			$scope.currentRangeUpperBound = $scope.transactionsInfo.offset + $scope.transactionsInfo.limit;
			if($scope.currentRangeUpperBound > $scope.transactionsInfo.total) $scope.currentRangeUpperBound = $scope.transactionsInfo.total;
		};
		
		$scope.fetchNextRange = function() {
			$scope.fetch($scope.transactionsInfo.offset + $scope.transactionsInfo.limit);
		};
		
		$scope.fetchPrevRange = function() {
			$scope.fetch($scope.transactionsInfo.offset - $scope.transactionsInfo.limit);
		};
		
		$scope.fetch = function(offset) {
			var to = offset + $scope.transactionsInfo.limit;
			$http.get('accounts/' + activeAccount.aggregate_id + '/transactions/' + offset + '-' + to + '.json').success(function(transactions) {
				jQuery.each(transactions, function(i, t) {
					t.date = new Date(t.date);
				});
				$scope.transactions = transactions
				$scope.transactionsInfo.offset = offset;
				$scope.refreshRangeState();
			});
		};
		
		$scope.adjustAmmount = function(transaction, ammount) {
			ammount = money.parse(ammount);
			return $http.post('transactions/' + transaction.transaction_id + '/adjust-ammount', {
				command: {ammount: ammount}
			}).success(function() {
				var oldAmmount = transaction.ammount;
				transaction.ammount = ammount;
				if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
					activeAccount.balance = activeAccount.balance - oldAmmount + ammount;
				} else if (transaction.type_id == Transaction.expenceId) {
					activeAccount.balance = activeAccount.balance + oldAmmount - ammount;
				}
			});
		};
		
		$scope.adjustTags = function(transaction, tag_ids) {
			return $http.post('transactions/' + transaction.transaction_id + '/adjust-tags', {
				command: {tag_ids: tag_ids}
			}).success(function() {
				transaction.tag_ids = tagsHelper.arrayToBracedString(tag_ids);
			});
		};
		
		$scope.adjustDate = function(transaction, date) {
			var jsonDate = date.toJSON();
			return $http.post('transactions/' + transaction.transaction_id + '/adjust-date', {
				command: {date: date.toJSON()}
			}).success(function() {
				transaction.date = date;
			});
		};
		
		$scope.adjustComment = function(transaction, comment) {
			return $http.post('transactions/' + transaction.transaction_id + '/adjust-comment', {
				command: {comment: comment}
			}).success(function() {
				transaction.comment = comment;
			});
		};
		
		$scope.removeTransaction = function(transaction) {
			return $http.delete('transactions/' + transaction.transaction_id).success(function() {
				$scope.transactions.splice($scope.transactions.indexOf(transaction), 1);
				if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
					activeAccount.balance -= transaction.ammount;
				} else if (transaction.type_id == Transaction.expenceId) {
					activeAccount.balance += transaction.ammount;
				}
			});
		};
		
		$scope.getTransactionTypeIcon = function(transaction) {
			if(transaction.is_transfer) return 'glyphicon-transfer';
			if(transaction.type_id == 1) return 'glyphicon-plus';
			if(transaction.type_id == 2) return 'glyphicon-minus';
			if(transaction.type_id == 3) return 'glyphicon-share-alt';
		};
		
		$scope.getTransferAmmountSign = function(transaction) {
			if(transaction.is_transfer) {
				return transaction.type_id == 2 ? '-' : '+';
			} else {
				return null;
			}
		};
	}]);

	homeApp.controller('ReportTransactionsController', ['$scope', '$http', 'activeAccountResolver', 'accounts', 'money',
	function ($scope, $http, activeAccountResolver, accounts, money) {
		var activeAccount = $scope.account = activeAccountResolver.resolve();
		$scope.accounts = accounts;
		$scope.reportedTransactions = [];
		//For testing purposes
		// $scope.reportedTransactions = [
		// 	{"type":"income","ammount":90,"tag_ids":'{1},{2}',"comment":"test123123","date":new Date("2014-07-16T21:09:27.000Z")},
		// 	{"type":"expence","ammount":2010,"tag_ids":'{2}',"comment":null,"date":new Date("2014-07-16T21:09:06.000Z")},
		// 	{"type":"expence","ammount":1050,"tag_ids":'{2},{3}',"comment":"Having lunch and getting some food","date":new Date("2014-07-16T21:08:51.000Z")},
		// 	{"type":"expence","ammount":1050,"tag_ids":null,"comment":"test1","date":new Date("2014-07-16T21:08:44.000Z")},
		// 	{"type":"expence","ammount":1050,"tag_ids":null,"comment":null,"date":new Date("2014-06-30T21:00:00.000Z")}
		// ];
		
		var processReportedTransaction = function(transaction) {
			if(transaction.type == Transaction.incomeKey || transaction.type == Transaction.refundKey) {
				activeAccount.balance += transaction.ammount;
			} else if(transaction.type == Transaction.expenceKey) {
				activeAccount.balance -= transaction.ammount;
			} else if(transaction.type == Transaction.transferKey) {
				activeAccount.balance -= transaction.ammount;
				$.each(accounts, function(index, account) {
					if(account.aggregate_id == transaction.receivingAccountId) {
						account.balance += money.parse(transaction.ammountReceived);
						return false;
					}
				});
			}
			
			transaction.tag_ids = jQuery.map(transaction.tag_ids, function(tag_id) {
				return '{' + tag_id + '}';
			}).join(',');
			$scope.reportedTransactions.unshift(transaction);
		};
		
		var resetNewTransaction = function() {
			$scope.newTransaction = {
				ammount: null,
				tag_ids: [],
				type: Transaction.expenceKey,
				date: new Date(),
				comment: null
			};
		};
		resetNewTransaction();
		$scope.report = function() {
			var command = {
				tag_ids: $scope.newTransaction.tag_ids,
				date: $scope.newTransaction.date.toJSON(),
				comment: $scope.newTransaction.comment
			};
			var ammount = money.parse($scope.newTransaction.ammount);
			if($scope.newTransaction.type == 'transfer') {
				command.receiving_account_id = $scope.newTransaction.receivingAccountId;
				command.ammount_sent = ammount;
				command.ammount_received = money.parse($scope.newTransaction.ammountReceived);
			} else {
				command.ammount = ammount;
			}
			$http.post('accounts/' + activeAccount.aggregate_id + '/transactions/report-' + $scope.newTransaction.type, {
				command: command
			}).success(function() {
				var reported = $scope.newTransaction;
				resetNewTransaction();
				reported.ammount = ammount;
				processReportedTransaction(reported);
			});
		};
	}]);

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