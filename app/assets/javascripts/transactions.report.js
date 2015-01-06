!function() {
	var transactionsApp = angular.module('transactionsApp');
	transactionsApp.controller('ReportTransactionsController', ['$scope', '$http', 'accounts', 'money',
	function ($scope, $http, accounts, money) {
		$scope.account = accounts.getActive();
		$scope.accounts = accounts.getAllOpen();
		$scope.reportedTransactions = [];
		//For testing purposes
		// $scope.reportedTransactions = [
		// 	{"type":"income","amount":90,"tag_ids":'{1},{2}',"comment":"test123123","date":new Date("2014-07-16T21:09:27.000Z")},
		// 	{"type":"expence","amount":2010,"tag_ids":'{2}',"comment":null,"date":new Date("2014-07-16T21:09:06.000Z")},
		// 	{"type":"expence","amount":1050,"tag_ids":'{2},{3}',"comment":"Having lunch and getting some food","date":new Date("2014-07-16T21:08:51.000Z")},
		// 	{"type":"refund","amount":1050,"tag_ids":'{2},{3}',"comment":"Having lunch and getting some food","date":new Date("2014-07-16T21:08:51.000Z")},
		// 	{"type":"expence","amount":1050,"tag_ids":null,"comment":"test1","date":new Date("2014-07-16T21:08:44.000Z")},
		// 	{"type":"transfer","amount":1050,"tag_ids":null,"comment":null,"date":new Date("2014-06-30T21:00:00.000Z")}
		// ];
	
		var processReportedTransaction = function(transaction) {
			if(transaction.type == Transaction.incomeKey || transaction.type == Transaction.refundKey) {
				$scope.account.balance += transaction.amount;
			} else if(transaction.type == Transaction.expenceKey) {
				$scope.account.balance -= transaction.amount;
			} else if(transaction.type == Transaction.transferKey) {
				$scope.account.balance -= transaction.amount;
				$.each(accounts.getAll(), function(index, account) {
					if(account.aggregate_id == transaction.receivingAccountId) {
						account.balance += money.parse(transaction.amountReceived);
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
				amount: null,
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
			var amount = money.parse($scope.newTransaction.amount);
			if($scope.newTransaction.type == 'transfer') {
				command.receiving_account_id = $scope.newTransaction.receivingAccountId;
				command.amount_sent = amount;
				command.amount_received = money.parse($scope.newTransaction.amountReceived);
			} else {
				command.amount = amount;
			}
			$http.post('accounts/' + $scope.account.aggregate_id + '/transactions/report-' + $scope.newTransaction.type, {
				command: command
			}).success(function() {
				var reported = $scope.newTransaction;
				resetNewTransaction();
				reported.amount = amount;
				processReportedTransaction(reported);
			});
		};
	}]);
}();