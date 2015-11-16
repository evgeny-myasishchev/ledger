describe('transactions.PendingTransactionsController', function() {
	var scope, $httpBackend, transactions, subject;
	var account1, account2, account3;
	
	beforeEach(function() {
		module('transactionsApp');
		angular.module('transactionsApp').config(['accountsProvider', function(accountsProvider) {
			accountsProvider.assignAccounts([
				account1 = {id: 1, aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, is_closed: false},
				account2 = {id: 2, aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, is_closed: false},
				account3 = {id: 3, aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200, is_closed: false}
			]);
		}]);
		inject(function(_$httpBackend_, $rootScope, _transactions_){
			$httpBackend = _$httpBackend_;
			transactions = _transactions_;
			$httpBackend.whenGET('pending-transactions.json').respond([]);
		});
	});
	
	function initController() {
		inject(function($rootScope, $controller) {
			scope = $rootScope.$new();
			subject = $controller('PendingTransactionsController', {$scope: scope});
		});
	};
	
	it('should fetch pending transactions', function() {
		$httpBackend.expectGET('pending-transactions.json').respond(
			[{t1: true}, {t2: true}, {t3: true}]
		);
		initController();
		$httpBackend.flush();
		expect(scope.transactions).toEqual([{t1: true}, {t2: true}, {t3: true}]);
	});
	
	it("should have dates converted to date object", function() {
		date = new Date();
		$httpBackend.expectGET('pending-transactions.json').respond(
			[{t1: true, date: date.toJSON()}, {t2: true, date: date.toJSON()}, {t3: true, date: date.toJSON()}]
		);
		initController();
		$httpBackend.flush();
		jQuery.each(scope.transactions, function(i, t) {
			expect(t.date).toEqual(date);
		});
	});
	
	it("should assign open accounts", function() {
		$httpBackend.expectGET('pending-transactions.json').respond([]);
		account3.is_closed = true;
		initController();
		$httpBackend.flush();
		expect(scope.accounts).toEqual([account1, account2]);
	});
	
	describe('startReview', function() {
		beforeEach(function() {
			initController();
		});
		
		it('should initialize pending transaction', function() {
			var transaction;
			scope.startReview(transaction = {
				transaction_id: 't-332',
				amount: '223.43',
				date: new Date(),
				comment: 'Comment 332',
				account_id: account1.aggregate_id,
				type_id: 2
			});
			
			expect(scope.pendingTransaction.transaction_id).toEqual(transaction.transaction_id);
			expect(scope.pendingTransaction.amount).toEqual(transaction.amount);
			expect(scope.pendingTransaction.date).toEqual(transaction.date);
			expect(scope.pendingTransaction.tag_ids).toEqual(transaction.tag_ids);
			expect(scope.pendingTransaction.comment).toEqual(transaction.comment);
			expect(scope.pendingTransaction.account).toEqual(account1);
			expect(scope.pendingTransaction.type_id).toEqual(transaction.type_id);
		});
		
		it('should leave the account null if pending transaction has no account assigned', function() {
			scope.startReview(transaction = {
				transaction_id: 't-332',
				amount: '223.43',
				date: new Date(),
				comment: 'Comment 332',
				account_id: null,
				type_id: 2
			});
			expect(scope.pendingTransaction.account).toBeNull();
		});
	});
	
	describe('adjustAndApprove', function() {
		var pendingTransaction;
		beforeEach(function() {
			initController();
			scope.pendingTransaction = pendingTransaction = {
				transaction_id: 't-332',
				amount: '223.43',
				date: new Date(),
				comment: 'Comment 332',
				account: account1,
				type_id: 2
			};
		});
		
		it("should submit the adjust-and-approve", function() {
			$httpBackend.expectPOST('pending-transactions/t-332/adjust-and-approve', function(data) {
				var expectedCommand = jQuery.extend({
					account_id: scope.pendingTransaction.account.aggregate_id
				}, scope.pendingTransaction);
				delete(expectedCommand.account);

				var command = JSON.parse(data);
				command.date = new Date(command.date);
				expect(command).toEqual(expectedCommand);
				return true;
			}).respond();
			scope.adjustAndApprove();
			$httpBackend.flush();
		});
		
		it("should submit the adjust-and-approve-transfer", function() {
			scope.pendingTransaction.receivingAccount = account2;
			scope.pendingTransaction.amount_received = '4432.03';
			scope.pendingTransaction.type_id = Transaction.transferKey;
			$httpBackend.expectPOST('pending-transactions/t-332/adjust-and-approve-transfer', function(data) {
				var expectedCommand = jQuery.extend({
					account_id: scope.pendingTransaction.account.aggregate_id,
					sending_account_id: scope.pendingTransaction.account.aggregate_id,
					receiving_account_id: scope.pendingTransaction.receivingAccount.aggregate_id,
					is_transfer: true
				}, scope.pendingTransaction);
				expectedCommand.type_id = Transaction.expenseId;
				delete(expectedCommand.account);
				delete(expectedCommand.receivingAccount);

				var command = JSON.parse(data);
				command.date = new Date(command.date);
				expect(command).toEqual(expectedCommand);
				return true;
			}).respond();
			scope.adjustAndApprove();
			$httpBackend.flush();
		});
		
		it("convert null tags to empty array", function() {
			$httpBackend.expectPOST('pending-transactions/t-332/adjust-and-approve', function(data) {
				var command = JSON.parse(data);
				expect(command.tag_ids).toEqual([]);
				return true;
			}).respond();
			scope.pendingTransaction.tag_ids = null;
			scope.adjustAndApprove();
			$httpBackend.flush();
		});
		
		it("convert type_id to integer", function() {
			$httpBackend.expectPOST('pending-transactions/t-332/adjust-and-approve', function(data) {
				var command = JSON.parse(data);
				expect(command.type_id).toEqual(1);
				return true;
			}).respond();
			scope.pendingTransaction.type_id = "1";
			scope.adjustAndApprove();
			$httpBackend.flush();
		});
		
		describe('on success', function() {
			var changeEventEmitted, approvedTransaction;
			beforeEach(function() {
				$httpBackend.flush();
				$httpBackend.whenPOST('pending-transactions/t-332/adjust-and-approve').respond();
				scope.approvedTransactions = [{t1: true}, {t2: true}];
				scope.transactions  = [{t1: true}, jQuery.extend({}, pendingTransaction), {t2: true}];
				scope.$on('pending-transactions-changed', function() {
					changeEventEmitted = true;
				});
				spyOn(transactions, 'processApprovedTransaction');
				scope.adjustAndApprove();
				$httpBackend.flush();
				
				approvedTransaction = jQuery.extend({
					account_id: pendingTransaction.account.aggregate_id
				}, pendingTransaction);
				approvedTransaction.amount = 22343;
				delete(approvedTransaction.account);
			});
			
			it('should insert the transaction into the beginning of approvedTransactions', function() {
				expect(scope.approvedTransactions.length).toEqual(3);
				expect(scope.approvedTransactions[0]).toEqual(approvedTransaction);
			});
			
			it('should convert amount to integer', function() {
				expect(scope.approvedTransactions[0].amount).toEqual(22343);
			});
			
			it('should clear the pending transaction', function() {
				expect(scope.pendingTransaction).toBeNull();
			});
			
			it('should remove the transaction from pendingTransactions', function() {
				expect(scope.transactions.length).toEqual(2);
				expect(scope.transactions).toEqual([{t1: true}, {t2: true}]);
			});
			
			it('should emit pending-transactions-changed event', function() {
				expect(changeEventEmitted).toBeTruthy();
			});
			
			it('should use transactions provider to process approved transaction', function() {
				expect(transactions.processApprovedTransaction).toHaveBeenCalledWith(approvedTransaction);
			});
		});
		
		describe('on success transfer', function() {
			beforeEach(function() {
				pendingTransaction.type_id = Transaction.transferKey;
				pendingTransaction.receivingAccount = account2;
				pendingTransaction.amount_received = '1009.32'
				$httpBackend.flush();
				$httpBackend.whenPOST('pending-transactions/t-332/adjust-and-approve-transfer').respond();
				scope.approvedTransactions = [{t1: true}, {t2: true}];
				scope.transactions  = [{t1: true}, jQuery.extend({}, pendingTransaction), {t2: true}];
				scope.adjustAndApprove();
				$httpBackend.flush();
			});
			
			it('should convert amount_received to integer', function() {
				expect(scope.approvedTransactions[0].amount_received).toEqual(100932);
			});
		});
	});

	describe('reject', function() {
		var pendingTransaction;
		beforeEach(function() {
			initController();
			scope.pendingTransaction = pendingTransaction = {
				transaction_id: 't-332',
				amount: '223.43',
				date: new Date(),
				comment: 'Comment 332',
				account: account1,
				type_id: 2
			};
		});
		
		it("should send delete request", function() {
			$httpBackend.expectDELETE('pending-transactions/t-332').respond();
			scope.reject();
			$httpBackend.flush();
			expect(scope.pendingTransaction).toBeNull();
		});
		
		describe('on success', function() {
			var changeEventEmitted;
			beforeEach(function() {
				$httpBackend.flush();
				$httpBackend.whenDELETE('pending-transactions/t-332').respond();
				scope.transactions  = [{t1: true}, pendingTransaction, {t2: true}];
				scope.$on('pending-transactions-changed', function() {
					changeEventEmitted = true;
				});
				scope.reject();
				$httpBackend.flush();
			});
			
			it('should remove the transaction from pendingTransactions', function() {
				expect(scope.transactions.length).toEqual(2);
				expect(scope.transactions).toEqual([{t1: true}, {t2: true}]);
			});
			
			it('should emit pending-transactions-changed event', function() {
				expect(changeEventEmitted).toBeTruthy();
			});
		});
	});
});