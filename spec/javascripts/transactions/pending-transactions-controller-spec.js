describe('transactions.PendingTransactionsController', function() {
	var scope, $httpBackend, pendingTransactions, subject;
	var account1, account2, account3;
	
	beforeEach(module('transactionsApp'));
	
	beforeEach(inject(function(_$httpBackend_, $rootScope, _pendingTransactions_){
		$httpBackend = _$httpBackend_;
		pendingTransactions = _pendingTransactions_;
		angular.module('transactionsApp').config(['accountsProvider', function(accountsProvider) {
			accountsProvider.assignAccounts([
				account1 = {id: 1, aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, is_closed: false},
				account2 = {id: 2, aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, is_closed: false},
				account3 = {id: 3, aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200, is_closed: false}
			]);
		}]);
		$httpBackend.whenGET('pending-transactions.json').respond([]);
	}));
	
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
				aggregate_id: 't-332',
				amount: '223.43',
				date: new Date(),
				tag_ids: "{t1},{t2}",
				comment: 'Comment 332',
				account_id: 44332,
				type_id: 2
			});
			
			expect(scope.pendingTransaction.aggregate_id).toEqual(transaction.aggregate_id);
			expect(scope.pendingTransaction.amount).toEqual(transaction.amount);
			expect(scope.pendingTransaction.date).toEqual(transaction.date);
			expect(scope.pendingTransaction.tag_ids).toEqual(transaction.tag_ids);
			expect(scope.pendingTransaction.comment).toEqual(transaction.comment);
			expect(scope.pendingTransaction.account_id).toEqual(transaction.account_id);
			expect(scope.pendingTransaction.type_id).toEqual(transaction.type_id);
		});
	});
	
	describe('adjustAndApprove', function() {
		var pendingTransaction;
		beforeEach(function() {
			initController();
			scope.pendingTransaction = pendingTransaction = {
				aggregate_id: 't-332',
				amount: '223.43',
				date: new Date(),
				tag_ids: "{t1},{t2}",
				comment: 'Comment 332',
				account_id: 44332,
				type_id: 2
			};
		});
		
		it("should submit the new income transaction", function() {
			$httpBackend.expectPOST('pending-transactions/t-332/adjust-and-approve', function(data) {
				var command = JSON.parse(data);
				command.date = new Date(command.date);
				expect(command).toEqual(scope.pendingTransaction);
				return true;
			}).respond();
			scope.adjustAndApprove();
			$httpBackend.flush();
		});
		
		describe('on success', function() {
			beforeEach(function() {
				$httpBackend.flush();
				$httpBackend.whenPOST('pending-transactions/t-332/adjust-and-approve').respond();
				scope.approvedTransactions = [{t1: true}, {t2: true}];
				scope.transactions  = [{t1: true}, pendingTransactions, {t2: true}];
				scope.adjustAndApprove();
				$httpBackend.flush();
			});
			
			it('should insert the transaction into the begining of approvedTransactions', function() {
				expect(scope.approvedTransactions.length).toEqual(3);
				expect(scope.approvedTransactions[0]).toEqual(pendingTransaction);
			});
			
			it('should convert amount to integer', function() {
				expect(scope.approvedTransactions[0].amount).toEqual(22343);
			});
			
			it('should rename aggregte_id to transaction_id', function() {
				expect(scope.approvedTransactions[0].aggregate_id).toBeUndefined();
				expect(scope.approvedTransactions[0].transaction_id).toEqual('t-332');
			});
			
			it('should clear the pending transaction', function() {
				expect(scope.pendingTransaction).toBeNull();
			});
			
			it('should remove the transaction from pendingTransactions', function() {
				expect(scope.transactions.length).toEqual(2);
			});
		});
	});
});