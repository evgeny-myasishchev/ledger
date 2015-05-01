describe("ReportTransactionsController", function() {
	var account1, account2, account3;
	var controller, scope,  $httpBackend;
	beforeEach(function() {
		module('transactionsApp');
		angular.module('transactionsApp').config(['accountsProvider', function(accountsProvider) {
			accountsProvider.assignAccounts([
				account1 = {id: 1, aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, is_closed: false},
				account2 = {id: 2, aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, is_closed: false},
				account3 = {id: 3, aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200, is_closed: false}
			]);
		}]);
		inject(function(_$httpBackend_) {
			$httpBackend = _$httpBackend_;
		});
		activeAccount = account2;
		HomeHelpers.include(this);
		this.assignActiveAccount(activeAccount);
	});
	
	function initController() {
		inject(function($rootScope, $controller) {
			scope = $rootScope.$new();
			controller = $controller('ReportTransactionsController', {$scope: scope});
		});
	}
	
	it("should assign active account", function() {
		activeAccount.balance = undefined;
		initController();
		expect(scope.account).toEqual(activeAccount);
	});
	
	it("should assign open accounts", function() {
		account3.is_closed = true;
		initController();
		expect(scope.accounts).toEqual([account1, account2]);
	});

	it("initializes initial scope", function() {
		initController();
		var currentDate = new Date();
		currentDate.setMilliseconds(0);
		scope.newTransaction.date.setMilliseconds(0);
		expect(scope.newTransaction.date.toJSON()).toEqual(currentDate.toJSON());
		expect(scope.newTransaction).toEqual({
			amount: null, tag_ids: [], type_id: Transaction.expenceId, date: scope.newTransaction.date, comment: null
		});
	});
	
	describe('newTransaction.amount changes', function() {
		beforeEach(function() {
			scope.newTransaction.type_id = null;
			scope.newTransaction.amount = null;
		});
		
		it('should set transaction type to income if amount is signed and positive', function() {
			scope.newTransaction.amount = "+1000";
			scope.$digest();
			expect(scope.newTransaction.type_id).toEqual(Transaction.incomeId);
		});
		
		it('should set transaction type to expense if amount is signed and negative', function() {
			scope.newTransaction.amount = "-1000";
			scope.$digest();
			expect(scope.newTransaction.type_id).toEqual(Transaction.expenceId);
		});
		
		it('should do nothing if amount has no sign', function() {
			scope.newTransaction.amount = "1000";
			scope.$digest();
			expect(scope.newTransaction.type_id).toBeNull();
		});
	});

	describe("report", function() {
		var date;
		beforeEach(function() {
			date = new Date();
			initController();
			scope.newTransaction.amount = '10.5';
			scope.newTransaction.tag_ids = [1, 2];
			scope.newTransaction.date = date;
			scope.newTransaction.comment = 'New transaction 10.5';
		});
		
		it("should submit the new income transaction", function() {
			scope.newTransaction.type_id = Transaction.incomeId;
			$httpBackend.expectPOST('accounts/a-2/transactions/report-income', function(data) {
				var command = JSON.parse(data);
				expect(command.transaction_id).not.toBeUndefined();
				expect(command.amount).toEqual(1050);
				expect(command.tag_ids).toEqual([1, 2]);
				expect(command.date).toEqual(date.toJSON());
				expect(command.comment).toEqual('New transaction 10.5');
				expect(command.type_id).toEqual(Transaction.incomeId);
				expect(command.account_id).toEqual('a-2');
				expect(command.is_transfer).toEqual(false);
				return true;
			}).respond();
			scope.report();
			$httpBackend.flush();
		});
	
		it("should submit the new expence transaction", function() {
			scope.newTransaction.type_id = Transaction.expenceId;;
			$httpBackend.expectPOST('accounts/a-2/transactions/report-expence', function(data) {
				var command = JSON.parse(data);
				expect(command.transaction_id).not.toBeUndefined();
				expect(command.amount).toEqual(1050);
				expect(command.tag_ids).toEqual([1, 2]);
				expect(command.date).toEqual(date.toJSON());
				expect(command.comment).toEqual('New transaction 10.5');
				expect(command.type_id).toEqual(Transaction.expenceId);
				expect(command.account_id).toEqual('a-2');
				expect(command.is_transfer).toEqual(false);
				return true;
			}).respond();

			scope.report();
			$httpBackend.flush();
		});
	
		it("should submit the new refund transaction", function() {
			scope.newTransaction.type_id = Transaction.refundId;;
			$httpBackend.expectPOST('accounts/a-2/transactions/report-refund', function(data) {
				var command = JSON.parse(data);
				expect(command.transaction_id).not.toBeUndefined();
				expect(command.amount).toEqual(1050);
				expect(command.tag_ids).toEqual([1, 2]);
				expect(command.date).toEqual(date.toJSON());
				expect(command.comment).toEqual('New transaction 10.5');
				expect(command.type_id).toEqual(Transaction.refundId);
				expect(command.account_id).toEqual('a-2');
				expect(command.is_transfer).toEqual(false);
				return true;
			}).respond();

			scope.report();
			$httpBackend.flush();
		});
	
		it("should submit the new transfer transaction", function() {
			scope.newTransaction.type_id = Transaction.transferKey;
			scope.newTransaction.receivingAccount = account2;
			scope.newTransaction.amount_received = '100.22';
			$httpBackend.expectPOST('accounts/a-2/transactions/report-transfer', function(data) {
				var command = JSON.parse(data);
				expect(command.sending_transaction_id).not.toBeUndefined();
				expect(command.sending_transaction_id).toEqual(command.transaction_id);
				expect(command.receiving_transaction_id).not.toBeUndefined();
				expect(command.receiving_account_id).toEqual('a-2');
				expect(command.amount).toEqual(1050);
				expect(command.amount_sent).toEqual(command.amount);
				expect(command.amount_received).toEqual(10022);
				expect(command.tag_ids).toEqual([1, 2]);
				expect(command.date).toEqual(date.toJSON());
				expect(command.comment).toEqual('New transaction 10.5');
				expect(command.type_id).toEqual(Transaction.expenceId);
				expect(command.account_id).toEqual('a-2');
				expect(command.is_transfer).toEqual(true);
				return true;
			}).respond();

			scope.report();
			$httpBackend.flush();
		});
		
		it("should use absolute value of amount for regular transactions", function() {
			scope.newTransaction.type_id = Transaction.incomeId;
			scope.newTransaction.amount = '-10.50';
			$httpBackend.whenPOST('accounts/a-2/transactions/report-income', function(data) {
				var command = JSON.parse(data);
				expect(command.amount).toEqual(1050);
				return true;
			}).respond();
			scope.report();
			$httpBackend.flush();
		});
		
		it("should use absolute value of amount for transfer", function() {
			scope.newTransaction.type_id = Transaction.transferKey;
			scope.newTransaction.receivingAccount = account2;
			scope.newTransaction.amount = '-10.50';
			scope.newTransaction.amount_received = '-10.50';
			$httpBackend.whenPOST('accounts/a-2/transactions/report-transfer', function(data) {
				var command = JSON.parse(data);
				expect(command.amount).toEqual(1050);
				expect(command.amount_sent).toEqual(1050);
				expect(command.amount_received).toEqual(1050);
				return true;
			}).respond();
			scope.report();
			$httpBackend.flush();
		});
	
		describe('on success', function() {
			var command;
			
			function doReport(typeId) {
				scope.newTransaction.type_id = typeId;
				var method = typeId == Transaction.transferKey ? typeId : Transaction.TypeKeyById[typeId];
				scope.reportedTransactions.push({test: true});
				$httpBackend.expectPOST('accounts/a-2/transactions/report-' + method, function(data) {
					command = JSON.parse(data);
					return true;
				}).respond();
				scope.report();
				$httpBackend.flush();
			};
		
			it("should insert the transaction into the begining of the reported transactions", function() {
				doReport(Transaction.expenceId);
				expect(scope.reportedTransactions.length).toEqual(2);
				expect(scope.reportedTransactions[0]).toEqual({
					transaction_id: command.transaction_id,
					account_id: 'a-2',
					amount: 1050, 
					tag_ids: '{1},{2}', 
					type_id: Transaction.expenceId, 
					date: date, 
					comment: 'New transaction 10.5',
					is_transfer: false
				});
			});
			
			it('should pupulate inserted transaction with transfer specific stuff', function() {
				scope.newTransaction.receivingAccount = account3;
				scope.newTransaction.amount_received = scope.newTransaction.amount;
				doReport(Transaction.transferKey);
				expect(scope.reportedTransactions[0]).toEqual({
					transaction_id: command.sending_transaction_id,
					account_id: 'a-2',
					amount: 1050,
					amount_sent: 1050,
					amount_received: 1050,
					tag_ids: '{1},{2}',
					type_id: Transaction.expenceId,
					date: date,
					comment: 'New transaction 10.5',
					is_transfer: true,
					sending_account_id: 'a-2',
					sending_transaction_id: command.sending_transaction_id,
					receiving_account_id: 'a-3',
					receiving_transaction_id: command.receiving_transaction_id
				});
			});
		
			it('should reset the newTransaction model', function() {
				doReport(Transaction.expenceId);
				expect(scope.newTransaction.amount).toBeNull();
				expect(scope.newTransaction.tag_ids).toEqual([]);
				expect(scope.newTransaction.comment).toBeNull();
			});
		});
	
		describe('on success update account balance', function() {
			beforeEach(function() {
				scope.account = account1;
				scope.account.balance = 500;
			});
		
			function doReport(amount, typeId) {
				scope.newTransaction.type_id = typeId;
				var method = typeId == Transaction.transferKey ? typeId : Transaction.TypeKeyById[typeId];
				$httpBackend.expectPOST('accounts/a-1/transactions/report-' + method).respond();
				scope.newTransaction.amount = amount;
				scope.newTransaction.type_id = typeId;
				scope.report();
				$httpBackend.flush();
			};
		
			it('should update the balance on income', function() {
				doReport(100, Transaction.incomeId);
				expect(scope.account.balance).toEqual(600);
			});
		
			it('should update the balance on expence', function() {
				doReport(100, Transaction.expenceId);
				expect(scope.account.balance).toEqual(400);
			});
		
			it('should update the balance on refund', function() {
				doReport(100, Transaction.refundId);
				expect(scope.account.balance).toEqual(600);
			});
		
			it('should update the balance on on transfer', function() {
				var receivingAccount = scope.accounts[1];
				receivingAccount.balance = 10000;
				scope.newTransaction.receivingAccount = receivingAccount;
				scope.newTransaction.amount_received = '50';
				doReport(100, Transaction.transferKey);
				expect(scope.account.balance).toEqual(400);
				expect(receivingAccount.balance).toEqual(15000);
			});
		});
	});
});
