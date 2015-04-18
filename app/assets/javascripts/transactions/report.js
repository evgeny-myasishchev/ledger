!function() {
	var transactionsApp = angular.module('transactionsApp');
	transactionsApp.controller('ReportTransactionsController', ['$scope', '$http', 'accounts', 'money', 'newUUID', 'transactions',
	function ($scope, $http, accounts, money, newUUID, transactions) {
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
	
		var processReportedTransaction = function(command) {
			transactions.processReportedTransaction(command);
			$scope.reportedTransactions.unshift(command);
		};
	
		var resetNewTransaction = function() {
			$scope.newTransaction = {
				amount: null,
				tag_ids: [],
				type_id: Transaction.expenceId,
				date: new Date(),
				comment: null
			};
			//For testing purposes
			// $scope.account = $scope.accounts[0];
			// $scope.newTransaction = {
			// 	amount: '332.03',
			// 	tag_ids: [1, 2],
			// 	type_id: Transaction.transferKey,
			// 	date: new Date(),
			// 	comment: 'Hello world, this is test transaction'
			// };
		};
		resetNewTransaction();
		$scope.report = function() {
			var command = {
				transaction_id: newUUID(),
				amount: money.parse($scope.newTransaction.amount),
				date: $scope.newTransaction.date,
				tag_ids: $scope.newTransaction.tag_ids,
				comment: $scope.newTransaction.comment,
				type_id: $scope.newTransaction.type_id,
				account_id: $scope.account.aggregate_id
			};
			var typeKey;
			if($scope.newTransaction.type_id == Transaction.transferKey) {
				typeKey = Transaction.transferKey;
				command.type_id = Transaction.expenceId;
				command.sending_account_id = command.account_id;
				command.sending_transaction_id = command.transaction_id;
				command.receiving_transaction_id = newUUID();
				command.receiving_account_id = $scope.newTransaction.receivingAccount.aggregate_id;
				command.amount_sent = command.amount;
				command.amount_received = money.parse($scope.newTransaction.amount_received);
				command.is_transfer = true;
			} else {
				typeKey = Transaction.TypeKeyById[$scope.newTransaction.type_id];
				command.is_transfer = false;
			}
			$http.post('accounts/' + $scope.account.aggregate_id + '/transactions/report-' + typeKey, {
				command: command
			}).success(function() {
				resetNewTransaction();
				processReportedTransaction(command);
			});
		};
	}]);
}();