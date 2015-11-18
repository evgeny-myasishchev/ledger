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
		HomeHelpers.include(this);
	});
	
	function initController() {
		inject(function($controller) {			
			controller = $controller('ReportTransactionsController');
		});
	}
	
	it("should assign active account", function() {
		this.assignActiveAccount(account2);
		initController();
		expect(controller.newTransaction.account).toEqual(account2);
	});
	
	it("should assign open accounts", function() {
		account3.is_closed = true;
		initController();
		expect(controller.accounts).toEqual([account1, account2]);
	});

	it("initializes initial attributes of the new transaction", function() {
		initController();
		var currentDate = new Date();
		currentDate.setMilliseconds(0);
		controller.newTransaction.date.setMilliseconds(0);
		expect(controller.newTransaction.date.toJSON()).toEqual(currentDate.toJSON());
		expect(controller.newTransaction).toEqual({
			account: null, amount: null, tag_ids: [], type_id: Transaction.expenseId, date: controller.newTransaction.date, comment: null
		});
	});

	describe("report", function() {
		var date;
		beforeEach(function() {
			date = new Date();
			initController();
			controller.newTransaction.account = account2;
			controller.newTransaction.amount = '10.5';
			controller.newTransaction.tag_ids = [1, 2];
			controller.newTransaction.date = date;
			controller.newTransaction.comment = 'New transaction 10.5';
		});
		
		it("should submit the new income transaction", function() {
			controller.newTransaction.type_id = Transaction.incomeId;
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
			controller.report();
			$httpBackend.flush();
		});
	
		it("should submit the new expense transaction", function() {
			controller.newTransaction.type_id = Transaction.expenseId;;
			$httpBackend.expectPOST('accounts/a-2/transactions/report-expense', function(data) {
				var command = JSON.parse(data);
				expect(command.transaction_id).not.toBeUndefined();
				expect(command.amount).toEqual(1050);
				expect(command.tag_ids).toEqual([1, 2]);
				expect(command.date).toEqual(date.toJSON());
				expect(command.comment).toEqual('New transaction 10.5');
				expect(command.type_id).toEqual(Transaction.expenseId);
				expect(command.account_id).toEqual('a-2');
				expect(command.is_transfer).toEqual(false);
				return true;
			}).respond();

			controller.report();
			$httpBackend.flush();
		});
	
		it("should submit the new refund transaction", function() {
			controller.newTransaction.type_id = Transaction.refundId;;
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

			controller.report();
			$httpBackend.flush();
		});
	
		it("should submit the new transfer transaction", function() {
			controller.newTransaction.type_id = Transaction.transferKey;
			controller.newTransaction.receivingAccount = account2;
			controller.newTransaction.amount_received = '100.22';
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
				expect(command.type_id).toEqual(Transaction.expenseId);
				expect(command.account_id).toEqual('a-2');
				expect(command.is_transfer).toEqual(true);
				return true;
			}).respond();

			controller.report();
			$httpBackend.flush();
		});
		
		it("should use absolute value of amount for regular transactions", function() {
			controller.newTransaction.type_id = Transaction.incomeId;
			controller.newTransaction.amount = '-10.50';
			$httpBackend.whenPOST('accounts/a-2/transactions/report-income', function(data) {
				var command = JSON.parse(data);
				expect(command.amount).toEqual(1050);
				return true;
			}).respond();
			controller.report();
			$httpBackend.flush();
		});
		
		it("should use absolute value of amount for transfer", function() {
			controller.newTransaction.type_id = Transaction.transferKey;
			controller.newTransaction.receivingAccount = account2;
			controller.newTransaction.amount = '-10.50';
			controller.newTransaction.amount_received = '-10.50';
			$httpBackend.whenPOST('accounts/a-2/transactions/report-transfer', function(data) {
				var command = JSON.parse(data);
				expect(command.amount).toEqual(1050);
				expect(command.amount_sent).toEqual(1050);
				expect(command.amount_received).toEqual(1050);
				return true;
			}).respond();
			controller.report();
			$httpBackend.flush();
		});
	
		describe('on success', function() {
			var command;
			
			function doReport(typeId) {
				controller.newTransaction.type_id = typeId;
				var method = typeId == Transaction.transferKey ? typeId : Transaction.TypeKeyById[typeId];
				controller.reportedTransactions.push({test: true});
				$httpBackend.expectPOST('accounts/a-2/transactions/report-' + method, function(data) {
					command = JSON.parse(data);
					return true;
				}).respond();
				controller.report();
				$httpBackend.flush();
			};
		
			it("should insert the transaction into the begining of the reported transactions", function() {
				doReport(Transaction.expenseId);
				expect(controller.reportedTransactions.length).toEqual(2);
				expect(controller.reportedTransactions[0]).toEqual({
					transaction_id: command.transaction_id,
					account_id: 'a-2',
					amount: 1050, 
					tag_ids: '{1},{2}', 
					type_id: Transaction.expenseId, 
					date: date, 
					comment: 'New transaction 10.5',
					is_transfer: false
				});
			});
			
			it('should pupulate inserted transaction with transfer specific stuff', function() {
				controller.newTransaction.receivingAccount = account3;
				controller.newTransaction.amount_received = controller.newTransaction.amount;
				doReport(Transaction.transferKey);
				expect(controller.reportedTransactions[0]).toEqual({
					transaction_id: command.sending_transaction_id,
					account_id: 'a-2',
					amount: 1050,
					amount_sent: 1050,
					amount_received: 1050,
					tag_ids: '{1},{2}',
					type_id: Transaction.expenseId,
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
				doReport(Transaction.expenseId);
				expect(controller.newTransaction.account).toBeNull();
				expect(controller.newTransaction.amount).toBeNull();
				expect(controller.newTransaction.tag_ids).toEqual([]);
				expect(controller.newTransaction.comment).toBeNull();
			});
			
			it('should assign active account value on reset', function() {
				this.assignActiveAccount(account3);
				doReport(Transaction.expenseId);
				expect(controller.newTransaction.account).toEqual(account3);
			});
		});
	
		describe('on success update account balance', function() {
			beforeEach(function() {
				controller.newTransaction.account = account1;
				account1.balance = 500;
			});
		
			function doReport(amount, typeId) {
				controller.newTransaction.type_id = typeId;
				var method = typeId == Transaction.transferKey ? typeId : Transaction.TypeKeyById[typeId];
				$httpBackend.expectPOST('accounts/a-1/transactions/report-' + method).respond();
				controller.newTransaction.amount = amount;
				controller.newTransaction.type_id = typeId;
				controller.report();
				$httpBackend.flush();
			};
		
			it('should update the balance on income', function() {
				doReport(100, Transaction.incomeId);
				expect(account1.balance).toEqual(600);
			});
		
			it('should update the balance on expense', function() {
				doReport(100, Transaction.expenseId);
				expect(account1.balance).toEqual(400);
			});
		
			it('should update the balance on refund', function() {
				doReport(100, Transaction.refundId);
				expect(account1.balance).toEqual(600);
			});
		
			it('should update the balance on on transfer', function() {
				account2.balance = 10000;
				controller.newTransaction.receivingAccount = account2;
				controller.newTransaction.amount_received = '50';
				doReport(100, Transaction.transferKey);
				expect(account1.balance).toEqual(400);
				expect(account2.balance).toEqual(15000);
			});
		});
	});
});
