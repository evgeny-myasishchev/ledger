describe('transactions.transactionsProvider', function() {
	var subject;
	var account1, account2, account3;
	
	beforeEach(module('transactionsApp'));

	beforeEach(function() {
		angular.module('transactionsApp').config(['transactionsProvider', 'accountsProvider', function(transactionsProvider, accountsProvider) {
			transactionsProvider.setPendingTransactionsCount(32);
			accountsProvider.assignAccounts([
				account1 = {id: 1, aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, is_closed: false},
				account2 = {id: 2, aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, is_closed: false},
				account3 = {id: 3, aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200, is_closed: false}
			]);
		}]);
	});

	beforeEach(inject(function(_transactions_){
		subject = _transactions_;
	}));
	
	describe('processReportedTransaction', function() {
		beforeEach(function() {
			account1.balance = 500;
		});
		
		function doProcess(amount, typeId, initializer) {
			var transaction = {
				account_id: account1.aggregate_id,
				type_id: typeId,
				amount: amount,
				tag_ids: []
			};
			if(initializer) initializer(transaction);
			subject.processReportedTransaction(transaction);
			return transaction;
		};
		
		it('should convert tags to braced string', function() {
			var transaction = doProcess(100, Transaction.incomeId, function(transaction) {
				transaction.tag_ids =[1, 2];
			});
			expect(transaction.tag_ids).toEqual('{1},{2}');
		});
	
		it('should update the balance on income', function() {
			doProcess(100, Transaction.incomeId);
			expect(account1.balance).toEqual(600);
		});

		it('should update the balance on expence', function() {
			doProcess(100, Transaction.expenceId);
			expect(account1.balance).toEqual(400);
		});

		it('should update the balance on refund', function() {
			doProcess(100, Transaction.refundId);
			expect(account1.balance).toEqual(600);
		});

		it('should update the balance on on transfer', function() {
			var receivingAccount = account2;
			receivingAccount.balance = 10000;
			doProcess(100, Transaction.expenceId, function(transaction) {
				transaction.is_transfer = true;
				transaction.receiving_account_id = receivingAccount.aggregate_id;
				transaction.amount_received = 5000;
			});
			expect(account1.balance).toEqual(400);
			expect(receivingAccount.balance).toEqual(15000);
		});
	});
});