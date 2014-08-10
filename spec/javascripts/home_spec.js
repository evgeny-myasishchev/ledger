describe("homeApp", function() {
	var account1, account2, account3;
	var controller, scope,  $httpBackend;
	beforeEach(function() {
		module('homeApp');
		scope = {};
		homeApp.constant('accounts',  [
			account1 = {id: 1, aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000},
			account2 = {id: 2, aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000},
			account3 = {id: 3, aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200}
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
	
	describe('HomeController', function() {
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
				controller = $controller('HomeController', {$scope: scope, $routeParams: routeParams});
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
		
		describe('transactions', function() {
			var transactions, date;
			beforeEach(function() {
				date = new Date();
				transactions = [
					{transaction1: true, date: date.toJSON()},
					{transaction2: true, date: date.toJSON()}
				];
				activeAccount.balance = 100
				$httpBackend.expectGET('accounts/a-1/transactions.json').respond({
					account_balance: 1193392,
					transactions_total: 4432,
					transactions_limit: 25,
					transactions: transactions
				});
				initController();
				spyOn(scope, 'refreshRangeState');
			});
			
			it("should be loaded for current account", function() {
			    expect(scope.transactions).toBeUndefined();
				$httpBackend.flush();
				expect(scope.transactions.length).toEqual(transactions.length);
			});
			
			it("should have dates converted to date object", function() {
				$httpBackend.flush();
				jQuery.each(scope.transactions, function(i, t) {
					expect(t.date).toEqual(date);
				});
			});
			
			it('should update account balance', function() {
				$httpBackend.flush();
				expect(activeAccount.balance).toEqual(1193392);
			});
			
			it('should assing transactions info', function() {
				$httpBackend.flush();
				expect(scope.transactionsInfo.total).toEqual(4432);
				expect(scope.transactionsInfo.offset).toEqual(0);
				expect(scope.transactionsInfo.limit).toEqual(25);
			});
			
			it('should call scope.refreshRangeState', function() {
				$httpBackend.flush();
				expect(scope.refreshRangeState).toHaveBeenCalled();
			});
		});
		
		describe('fetching transactions range', function() {
			beforeEach(function() {
				$httpBackend.whenGET('accounts/a-1/transactions.json').respond({transactions: []});
				initController();
				$httpBackend.flush();
			});
			
			it('should let fetching only if total is more than limit', function() {
				scope.transactionsInfo.total = 20;
				scope.transactionsInfo.limit = 21;
				scope.refreshRangeState();
				expect(scope.canFetchRanges).toBeFalsy();
				scope.transactionsInfo.limit = 19;
				scope.refreshRangeState();
				expect(scope.canFetchRanges).toBeTruthy();
			});
			
			it('should let fetching next range if it will not exceed total', function() {
				scope.transactionsInfo.total = 21;
				scope.transactionsInfo.limit = 5;
				scope.transactionsInfo.offset = 10;
				scope.refreshRangeState();
				expect(scope.canFetchNextRange).toBeTruthy();
				scope.transactionsInfo.offset = 20;
				scope.refreshRangeState();
				expect(scope.canFetchNextRange).toBeFalsy();
			});
			
			it('should let fetching prev range if it will not become lower than zero', function() {
				scope.transactionsInfo.total = 6;
				scope.transactionsInfo.limit = 5;
				scope.transactionsInfo.offset = 6;
				scope.refreshRangeState();
				expect(scope.canFetchPrevRange).toBeTruthy();
				scope.transactionsInfo.offset = 5;
				scope.refreshRangeState();
				expect(scope.canFetchPrevRange).toBeTruthy();
				scope.transactionsInfo.offset = 4;
				scope.refreshRangeState();
				expect(scope.canFetchPrevRange).toBeFalsy();
			});
			
			it('should calculate currentRangeUpperBound', function() {
				scope.transactionsInfo.total = 21;
				scope.transactionsInfo.limit = 5;
				scope.transactionsInfo.offset = 6;
				scope.refreshRangeState();
				expect(scope.currentRangeUpperBound).toEqual(11);
				scope.transactionsInfo.offset = 19;
				scope.refreshRangeState();
				expect(scope.currentRangeUpperBound).toEqual(21);
			});
			
			it('should fetch next page on fetchNextRange', function() {
				scope.transactionsInfo.offset = 10;
				scope.transactionsInfo.limit = 20;
				spyOn(scope, 'fetch');
				scope.fetchNextRange();
				expect(scope.fetch).toHaveBeenCalledWith(30);
			});
		
			it('should fetch prev page on fetchPrevRange', function() {
				scope.transactionsInfo.offset = 40;
				scope.transactionsInfo.limit = 20;
				spyOn(scope, 'fetch');
				scope.fetchPrevRange();
				expect(scope.fetch).toHaveBeenCalledWith(20);
			});
			
			describe('fetch', function() {
				beforeEach(function() {
					date = new Date();
					transactions = [
						{transaction1: true, date: date.toJSON()},
						{transaction2: true, date: date.toJSON()}
					];
					$httpBackend.expectGET('accounts/a-1/transactions/10-20.json').respond(transactions);
					spyOn(scope, 'refreshRangeState');
					scope.transactionsInfo.limit = 10;
					scope.fetch(10);
					$httpBackend.flush();
				});
				
				it('should get transactions range for given account and given offset', function() {
					expect(scope.transactions.length).toEqual(transactions.length);
				});
				
				it("should have dates converted to date object", function() {
					jQuery.each(scope.transactions, function(i, t) {
						expect(t.date).toEqual(date);
					});
				});
				
				it('should have new offset assigned', function() {
					expect(scope.transactionsInfo.offset).toEqual(10);
				});
				
				it('should call scope.refreshRangeState', function() {
					expect(scope.refreshRangeState).toHaveBeenCalled();
				});
			});
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
				$httpBackend.whenGET('accounts/a-1/transactions.json').respond({
					transactions: [transaction, {transaction_id: 't-1'}, {transaction_id: 't-2'}]
				});
				initController();
				$httpBackend.flush();
				transaction = jQuery.grep(scope.transactions, function(t) { return t.transaction_id == 't-223'})[0];
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
						expect(command.ammount).toEqual(20043);
						return true;
					}).respond(200);
					var result = scope.adjustAmmount(transaction, 20043);
					$httpBackend.flush();
					expect(transaction.ammount).toEqual(20043);
					expect(result.then).toBeDefined();
				});
				
				it('should parse money string', function() {
					$httpBackend.expectPOST('transactions/t-223/adjust-ammount', function(data) {
						var command = JSON.parse(data).command;
						expect(command.ammount).toEqual(20043);
						return true;
					}).respond(200);
					var result = scope.adjustAmmount(transaction, '200.43');
					$httpBackend.flush();
					expect(transaction.ammount).toEqual(20043);
				});
				
				describe('update activeAccount balance', function() {
					beforeEach(function() {
						$httpBackend.expectPOST('transactions/t-223/adjust-ammount').respond(200);
						activeAccount.balance = 250;
						transaction.ammount = 50;
					});
					
					it('should update the balance for income transaction', function() {
						transaction.type_id = Transaction.incomeId;
						scope.adjustAmmount(transaction, 100);
						$httpBackend.flush();
						expect(activeAccount.balance).toEqual(300);
					});
					
					it('should update the balance for refund transaction', function() {
						transaction.type_id = Transaction.refundId;
						scope.adjustAmmount(transaction, 100);
						$httpBackend.flush();
						expect(activeAccount.balance).toEqual(300);
					});
					
					it('should update the balance for expence transaction', function() {
						transaction.type_id = Transaction.expenceId;
						scope.adjustAmmount(transaction, 100);
						$httpBackend.flush();
						expect(activeAccount.balance).toEqual(200);
					});
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
					expect(transaction.tag_ids).toEqual('{10},{20},{40}');
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
					expect(transaction.date).toEqual(newDate);
					expect(result.then).toBeDefined();
				});
			});
			
			describe('removeTransaction', function() {
				beforeEach(function() {
					$httpBackend.whenDELETE('transactions/t-223').respond(200);
				});
				
				it('should DELETE destroy for given transaction', function() {
					$httpBackend.expectDELETE('transactions/t-223').respond(200);
					var result = scope.removeTransaction(transaction);
					$httpBackend.flush();
					expect(result.then).toBeDefined();
				});
				
				describe('activeAccount.balance', function() {
					beforeEach(function() {
						activeAccount.balance = 5000;
						transaction.ammount = 1000;
					});
					
					it('should subtract for income or refund', function() {
						transaction.type_id = Transaction.incomeId;
						scope.removeTransaction(transaction);
						$httpBackend.flush();
						expect(activeAccount.balance).toEqual(4000);
						
						transaction.type_id = Transaction.refundId;
						scope.removeTransaction(transaction);
						$httpBackend.flush();
						expect(activeAccount.balance).toEqual(3000);
					});
				
					it('should add for expence', function() {
						transaction.type_id = Transaction.expenceId;
						scope.removeTransaction(transaction);
						$httpBackend.flush();
						expect(activeAccount.balance).toEqual(6000);
					});
				})
				
				it('should remove the transaction from scope on success', function() {
					scope.removeTransaction(transaction);
					$httpBackend.flush();
					expect(scope.transactions).not.toContain(transaction);
				});
			});
		});
	});

	describe('ReportTransactionsController', function() {
		var scope;
		beforeEach(function() {
			activeAccount = account1;
			routeParams = {};
		});
		
		function initController() {
			inject(function($rootScope, $controller) {
				scope = $rootScope.$new();
				controller = $controller('ReportTransactionsController', {$scope: scope});
			});
		}

		it("should assign active account from the accessor", function() {
			activeAccount.balance = undefined;
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
					expect(command.ammount).toEqual(1050);
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
					expect(command.ammount).toEqual(1050);
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
					expect(command.ammount).toEqual(1050);
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
				scope.newTransaction.ammountReceived = '100.22';
				$httpBackend.expectPOST('accounts/a-1/transactions/report-transfer', function(data) {
					var command = JSON.parse(data).command;
					expect(command.receiving_account_id).toEqual('a-2');
					expect(command.ammount_sent).toEqual(1050);
					expect(command.ammount_received).toEqual(10022);
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
					$httpBackend.expectPOST('accounts/a-1/transactions/report-expence').respond();
					scope.report();
					$httpBackend.flush();
				});
				
				it("should insert the transaction into the begining of the reported transactions", function() {
					expect(scope.reportedTransactions.length).toEqual(2);
					expect(scope.reportedTransactions[0]).toEqual({
						ammount: 1050, tag_ids: '{1},{2}', type: 'expence', date: date, comment: 'New transaction 10.5'
					});
				});
				
				it('should reset the newTransaction model', function() {
					expect(scope.newTransaction.ammount).toBeNull();
					expect(scope.newTransaction.tag_ids).toEqual([]);
					expect(scope.newTransaction.comment).toBeNull();
				});
			});
			
			describe('on success update activeAccount balance', function() {
				beforeEach(function() {
					scope.account.balance = 500;
				});
				
				function doReport(ammount, typeKey) {
					$httpBackend.expectPOST('accounts/a-1/transactions/report-' + typeKey).respond();
					scope.newTransaction.ammount = ammount;
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
					scope.newTransaction.ammountReceived = '50';
					doReport(100, Transaction.transferKey);
					expect(scope.account.balance).toEqual(400);
					expect(receivingAccount.balance).toEqual(15000);
				});
			});
		});
	});

});
