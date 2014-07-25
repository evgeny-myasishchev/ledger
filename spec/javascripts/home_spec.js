describe("homeApp", function() {
	var account1, account2, account3;
	var controller, scope,  $httpBackend;
	beforeEach(function() {
		module('homeApp');
		scope = {};
		homeApp.constant('accounts',  [
			account1 = {id: 1, aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': '100 UAH'},
			account2 = {id: 2, aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': '200 UAH'},
			account3 = {id: 3, aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': '4432 UAH'}
		]);
		homeApp.value('tags', []); //It has to be value so it could be redefined in other specs
		inject(function(_$httpBackend_) {
			$httpBackend = _$httpBackend_;
		});
	});

	describe('activeAccountResolver', function() {
		var routeParams, resolver;
		beforeEach(function() {
			inject(function($routeParams) {
				routeParams = $routeParams;
			});
		});
		
		function initResolver() {
			inject(function($injector) {
				resolver = $injector.get('activeAccountResolver');
			});
		}

		it("should set active account from route params", function() {
			routeParams.accountSequentialNumber = account2.sequential_number;
			initResolver();
			expect(resolver.resolve()).toEqual(account2);
		});

		it("should change active account if route params changed", function() {
			routeParams.accountSequentialNumber = account1.sequential_number;
			initResolver();
			routeParams.accountSequentialNumber = account2.sequential_number;
			expect(resolver.resolve()).toEqual(account2);
		});
		
		it("should set first account as active if no accountId in params", function() {
			initResolver();
			expect(resolver.resolve()).toEqual(account1);
		});
	});
	
	describe('AccountsController', function() {
		var routeParams, activeAccount;
		beforeEach(function() {
			activeAccount = account1;
			homeApp.service('activeAccountResolver', function() {
				this.resolve = function() { return activeAccount; }
			});
			routeParams = {};
		});
		
		function initController() {
			inject(function($rootScope, $controller) {
				scope = $rootScope.$new();
				controller = $controller('AccountsController', {$scope: scope, $routeParams: routeParams});
			});
		}
		
		it("should have default accounts", function() {
			initController();
			expect(scope.accounts.length).toEqual(3);
		});
		
		it("should set active account from accessor", function() {
			activeAccount = account2;
			initController();
			expect(scope.activeAccount).toEqual(account2);
		});
		
		it("should get the transactions for active account from the server", function() {
			var transactions = [
				{transaction1: true},
				{transaction2: true}
			];
			$httpBackend.expectGET('accounts/a-1/transactions.json').respond(transactions);
			initController();
		    expect(scope.transactions).toBeUndefined();
			$httpBackend.flush();
			expect(scope.transactions).toEqual(transactions);
		});
		
		describe('getTransactionTypeIcon', function() {
			var transaction;
			beforeEach(function() {
				transaction = {type_id: -100, is_transfer: false};
				initController();
			});
			it('should return transfer icon if transaction is transfer', function() {
				transaction.is_transfer = true;
				expect(scope.getTransactionTypeIcon(transaction)).toEqual('glyphicon-transfer');
			});
			it('should return income specific icon if transaction is income', function() {
				transaction.type_id = 1;
				expect(scope.getTransactionTypeIcon(transaction)).toEqual('glyphicon-plus');
			});
			it('should return expence specific icon if transaction is expence', function() {
				transaction.type_id = 2;
				expect(scope.getTransactionTypeIcon(transaction)).toEqual('glyphicon-minus');
			});
			it('should return refund specific icon if transaction is refund', function() {
				transaction.type_id = 3;
				expect(scope.getTransactionTypeIcon(transaction)).toEqual('glyphicon-share-alt');
			});
		});
		
		describe("getTransferAmmountSign", function() {
			var transaction;
			beforeEach(function() {
				transaction = {type_id: -100, is_transfer: true};
				initController();
			});

			it("should return + sign for transfer income", function() {
				transaction.type_id = 1;
				expect(scope.getTransferAmmountSign(transaction)).toEqual('+');
			});

			it("should return - sign for transfer expence", function() {
				transaction.type_id = 2;
				expect(scope.getTransferAmmountSign(transaction)).toEqual('-');
			});
			
			it("should return empty for other transactions", function() {
				transaction.type_id = 2;
				transaction.is_transfer = false;
				expect(scope.getTransferAmmountSign(transaction)).toBeNull();
			});
		});
		
		describe('adjust transaction', function() {
			var transaction;
			beforeEach(function() {
				var date = new Date();
				date.setHours(date.getHours() -  10);
				transaction = {
					transaction_id: 't-223', 
					ammount: '100.23',
					tag_ids: [20],
					date: date.toJSON(),
					comment: 'Original comment'
				};
				$httpBackend.whenGET('accounts/a-1/transactions.json').respond([transaction, {transaction_id: 't-1'}, , {transaction_id: 't-2'}]);
				initController();
			});
			describe('adjustComment', function() {
				it('should post adjust-comment for given transaction', function() {
					$httpBackend.expectPOST('transactions/t-223/adjust-comment', function(data) {
						var command = JSON.parse(data).command;
						expect(command.comment).toEqual('New comment 223');
						return true;
					}).respond(200);
					var result = scope.adjustComment(transaction, 'New comment 223');
					$httpBackend.flush();
					expect(transaction.comment).toEqual('New comment 223');
					expect(result.then).toBeDefined();
				});
			});
			describe('adjustAmmount', function() {
				it('should post adjust-ammount for given transaction', function() {
					$httpBackend.expectPOST('transactions/t-223/adjust-ammount', function(data) {
						var command = JSON.parse(data).command;
						expect(command.ammount).toEqual('200.43');
						return true;
					}).respond(200);
					var result = scope.adjustAmmount(transaction, '200.43');
					$httpBackend.flush();
					expect(transaction.ammount).toEqual('200.43');
					expect(result.then).toBeDefined();
				});
			});
			describe('adjustTags', function() {
				it('should post adjust-tags for given transaction', function() {
					$httpBackend.expectPOST('transactions/t-223/adjust-tags', function(data) {
						var command = JSON.parse(data).command;
						expect(command.tag_ids).toEqual([10, 20, 40]);
						return true;
					}).respond(200);
					var result = scope.adjustTags(transaction, [10, 20, 40]);
					$httpBackend.flush();
					expect(transaction.tag_ids).toEqual([10, 20, 40]);
					expect(result.then).toBeDefined();
				});
			});
			describe('adjustDate', function() {
				it('should post adjust-date for given transaction', function() {
					var newDate = new Date();
					$httpBackend.expectPOST('transactions/t-223/adjust-date', function(data) {
						var command = JSON.parse(data).command;
						expect(command.date).toEqual(newDate.toJSON());
						return true;
					}).respond(200);
					var result = scope.adjustDate(transaction, newDate);
					$httpBackend.flush();
					expect(transaction.date).toEqual(newDate.toJSON());
					expect(result.then).toBeDefined();
				});
			});
		});
	});

	describe('ReportTransactionsController', function() {
		var activeAccount, scope;
		beforeEach(function() {
			activeAccount = {id: 1, aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': '100 UAH'};
			routeParams = {};
		});
		
		function initController() {
			inject(function($rootScope, $controller) {
				scope = $rootScope.$new();
				controller = $controller('ReportTransactionsController', {$scope: scope});
			});
		}

		it("should assign active account from the accessor", function() {
			initController();
			expect(scope.account).toEqual(activeAccount);
		});
		
		it("initializes initial scope", function() {
			initController();
			expect(scope.newTransaction.date.toJSON()).toEqual(new Date().toJSON());
			scope.newTransaction.date = null;
			expect(scope.newTransaction).toEqual({
				ammount: null, tag_ids: [], type: 'expence', date: null, comment: null
			});
		});
		
		describe("report", function() {
			var date;
			beforeEach(function() {
				date = new Date();
				initController();
				scope.newTransaction.ammount = '10.5';
				scope.newTransaction.tag_ids = [1, 2];
				scope.newTransaction.date = date;
				scope.newTransaction.comment = 'New transaction 10.5';
			});
			
			it("should submit the new income transaction", function() {
				scope.newTransaction.type = 'income';
				$httpBackend.expectPOST('accounts/a-1/transactions/report-income', function(data) {
					var command = JSON.parse(data).command;
					expect(command.ammount).toEqual('10.5');
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
				$httpBackend.expectPOST('accounts/a-1/transactions/report-expence', function(data) {
					var command = JSON.parse(data).command;
					expect(command.ammount).toEqual('10.5');
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
				$httpBackend.expectPOST('accounts/a-1/transactions/report-refund', function(data) {
					var command = JSON.parse(data).command;
					expect(command.ammount).toEqual('10.5');
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
				scope.newTransaction.receivingAccount = {aggregate_id: 'a-2'};
				scope.newTransaction.ammountReceived = '100.22';
				$httpBackend.expectPOST('accounts/a-1/transactions/report-transfer', function(data) {
					var command = JSON.parse(data).command;
					expect(command.receiving_account_id).toEqual('a-2');
					expect(command.ammount_sent).toEqual('10.5');
					expect(command.ammount_received).toEqual('100.22');
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
					$httpBackend.expectPOST('accounts/a-1/transactions/report-expence').respond();
					scope.report();
					$httpBackend.flush();
				});
				
				it("should insert the transaction into reported transaction", function() {
					expect(scope.reportedTransactions.length).toEqual(1);
					expect(scope.reportedTransactions[0]).toEqual({
						ammount: '10.5', tag_ids: '{1},{2}', type: 'expence', date: date, comment: 'New transaction 10.5'
					});
				});
				
				it('should reset the newTransaction model', function() {
					expect(scope.newTransaction.ammount).toBeNull();
					expect(scope.newTransaction.tag_ids).toEqual([]);
					expect(scope.newTransaction.comment).toBeNull();
				});
			});
		});
	});
});
