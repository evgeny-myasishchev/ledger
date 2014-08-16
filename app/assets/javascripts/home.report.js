!function() {
	var homeApp = angular.module('homeApp');
	homeApp.controller('ReportTransactionsController', ['$scope', '$http', 'accounts', 'money',
	function ($scope, $http, accounts, money) {
		var activeAccount = $scope.account = accounts.getActive();
		$scope.accounts = accounts.getAll();
		$scope.reportedTransactions = [];
		//For testing purposes
		// $scope.reportedTransactions = [
		// 	{"type":"income","ammount":90,"tag_ids":'{1},{2}',"comment":"test123123","date":new Date("2014-07-16T21:09:27.000Z")},
		// 	{"type":"expence","ammount":2010,"tag_ids":'{2}',"comment":null,"date":new Date("2014-07-16T21:09:06.000Z")},
		// 	{"type":"expence","ammount":1050,"tag_ids":'{2},{3}',"comment":"Having lunch and getting some food","date":new Date("2014-07-16T21:08:51.000Z")},
		// 	{"type":"refund","ammount":1050,"tag_ids":'{2},{3}',"comment":"Having lunch and getting some food","date":new Date("2014-07-16T21:08:51.000Z")},
		// 	{"type":"expence","ammount":1050,"tag_ids":null,"comment":"test1","date":new Date("2014-07-16T21:08:44.000Z")},
		// 	{"type":"transfer","ammount":1050,"tag_ids":null,"comment":null,"date":new Date("2014-06-30T21:00:00.000Z")}
		// ];
	
		var processReportedTransaction = function(transaction) {
			if(transaction.type == Transaction.incomeKey || transaction.type == Transaction.refundKey) {
				activeAccount.balance += transaction.ammount;
			} else if(transaction.type == Transaction.expenceKey) {
				activeAccount.balance -= transaction.ammount;
			} else if(transaction.type == Transaction.transferKey) {
				activeAccount.balance -= transaction.ammount;
				$.each(accounts.getAll(), function(index, account) {
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
}();