describe("ReportTransactionsController", function() {
	var account1, account2, account3;
	var controller, scope,  $httpBackend;
	beforeEach(function() {
		module('homeApp');
		homeApp.config(['accountsProvider', function(accountsProvider) {
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
		scope.newTransaction.date = null;
		expect(scope.newTransaction).toEqual({
			amount: null, tag_ids: [], type: 'expence', date: null, comment: null
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
			scope.newTransaction.type = 'income';
			$httpBackend.expectPOST('accounts/a-2/transactions/report-income', function(data) {
				var command = JSON.parse(data).command;
				expect(command.amount).toEqual(1050);
				expect(command.tag_ids).toEqual([1, 2]);
				expect(command.date).toEqual(date.toJSON());
				expect(command.comment).toEqual('New transaction 10.5');
				return true;
			}).respond();
			scope.report();
			$httpBackend.flush();
		});
	
		it("should submit the new expence transaction", function() {
			scope.newTransaction.type = 'expence';
			$httpBackend.expectPOST('accounts/a-2/transactions/report-expence', function(data) {
				var command = JSON.parse(data).command;
				expect(command.amount).toEqual(1050);
				expect(command.tag_ids).toEqual([1, 2]);
				expect(command.date).toEqual(date.toJSON());
				expect(command.comment).toEqual('New transaction 10.5');
				return true;
			}).respond();

			scope.report();
			$httpBackend.flush();
		});
	
		it("should submit the new refund transaction", function() {
			scope.newTransaction.type = 'refund';
			$httpBackend.expectPOST('accounts/a-2/transactions/report-refund', function(data) {
				var command = JSON.parse(data).command;
				expect(command.amount).toEqual(1050);
				expect(command.tag_ids).toEqual([1, 2]);
				expect(command.date).toEqual(date.toJSON());
				expect(command.comment).toEqual('New transaction 10.5');
				return true;
			}).respond();

			scope.report();
			$httpBackend.flush();
		});
	
		it("should submit the new transfer transaction", function() {
			scope.newTransaction.type = 'transfer';
			scope.newTransaction.receivingAccountId = account2.aggregate_id;
			scope.newTransaction.amountReceived = '100.22';
			$httpBackend.expectPOST('accounts/a-2/transactions/report-transfer', function(data) {
				var command = JSON.parse(data).command;
				expect(command.receiving_account_id).toEqual('a-2');
				expect(command.amount_sent).toEqual(1050);
				expect(command.amount_received).toEqual(10022);
				expect(command.tag_ids).toEqual([1, 2]);
				expect(command.date).toEqual(date.toJSON());
				expect(command.comment).toEqual('New transaction 10.5');
				return true;
			}).respond();

			scope.report();
			$httpBackend.flush();
		});
	
		describe('on success', function() {
			beforeEach(function() {
				scope.reportedTransactions.push({test: true});
				$httpBackend.expectPOST('accounts/a-2/transactions/report-expence').respond();
				scope.report();
				$httpBackend.flush();
			});
		
			it("should insert the transaction into the begining of the reported transactions", function() {
				expect(scope.reportedTransactions.length).toEqual(2);
				expect(scope.reportedTransactions[0]).toEqual({
					amount: 1050, tag_ids: '{1},{2}', type: 'expence', date: date, comment: 'New transaction 10.5'
				});
			});
		
			it('should reset the newTransaction model', function() {
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
		
			function doReport(amount, typeKey) {
				$httpBackend.expectPOST('accounts/a-1/transactions/report-' + typeKey).respond();
				scope.newTransaction.amount = amount;
				scope.newTransaction.type = typeKey;
				scope.report();
				$httpBackend.flush();
			}
		
			it('should update the balance on income', function() {
				doReport(100, Transaction.incomeKey);
				expect(scope.account.balance).toEqual(600);
			});
		
			it('should update the balance on expence', function() {
				doReport(100, Transaction.expenceKey);
				expect(scope.account.balance).toEqual(400);
			});
		
			it('should update the balance on refund', function() {
				doReport(100, Transaction.refundKey);
				expect(scope.account.balance).toEqual(600);
			});
		
			it('should update the balance on on transfer', function() {
				var receivingAccount = scope.accounts[1];
				receivingAccount.balance = 10000;
				scope.newTransaction.receivingAccountId = receivingAccount.aggregate_id;
				scope.newTransaction.amountReceived = '50';
				doReport(100, Transaction.transferKey);
				expect(scope.account.balance).toEqual(400);
				expect(receivingAccount.balance).toEqual(15000);
			});
		});
	});
});
