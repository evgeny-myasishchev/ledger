describe("homeApp", function() {
	var account1, account2, account3;
	var controller, scope,  $httpBackend;
	var category1, category2;
	var routeParams;
	beforeEach(function() {
		module('homeApp');
		scope = {};
		homeApp.config(['accountsProvider', function(accountsProvider) {
			accountsProvider.assignAccounts([
				account1 = {aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000},
				account2 = {aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000},
				account3 = {aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200}
			]);
			accountsProvider.assignCategories([
				category1 = {id: 1, display_order: 1, name: 'Category 1'},
				category2 = {id: 1, display_order: 2, name: 'Category 2'}
			]);
		}]);
		inject(function(_$httpBackend_) {
			$httpBackend = _$httpBackend_;
		});
	});
	
	describe('accountsStateProvider', function() {
		var provider;
		beforeEach(function() {
			inject(['accountsState', function(p) { provider = p;}]);
		});
		
		it('should get/set if showing closed accounts', function() {
			expect(provider.showingClosed()).toBeFalsy();
			expect(provider.showingClosed(true)).toBeTruthy();
			expect(provider.showingClosed()).toBeTruthy();
		});
	});
	
	describe('HomeController', function() {
		var activeAccount;
		beforeEach(function() {
			activeAccount = account1;
			routeParams = {};
			HomeHelpers.include(this);
			this.assignActiveAccount(activeAccount);
		});
		
		function initController() {
			inject(function($rootScope, $controller) {
				scope = $rootScope.$new();
				controller = $controller('HomeController', {$scope: scope, $routeParams: routeParams});
			});
		}
		
		it("should set active account from accessor", function() {
			this.assignActiveAccount(account2);
			initController();
			expect(scope.activeAccount).toEqual(account2);
		});
		
		describe('renameAccount', function() {
			beforeEach(function() {
				$httpBackend.whenGET('accounts/a-1/transactions.json').respond({ transactions: [] });
				initController();
				$httpBackend.flush();
			});
			it('should post rename for given account', function() {
				$httpBackend.expectPUT('accounts/a-2/rename', function(data) {
					var command = JSON.parse(data);
					expect(command.name).toEqual('New name 223');
					return true;
				}).respond(200);
				var result = scope.renameAccount(account2, 'New name 223');
				$httpBackend.flush();
				expect(account2.name).toEqual('New name 223');
				expect(result.then).toBeDefined();
			});
		});
		
		describe('close/reopen/remove account', function() {
			beforeEach(function() {
				$httpBackend.whenGET('accounts/a-1/transactions.json').respond({ transactions: [] });
				initController();
				$httpBackend.flush();
				HomeHelpers.include(this);
				this.assignActiveLedger({aggregate_id: 'ledger-332'});
			});
			
			it('should post close for given account and update closed flag on success when closing', function() {
				$httpBackend.expectPOST('ledgers/ledger-332/accounts/a-2/close').respond(200);
				var result = scope.closeAccount(account2);
				$httpBackend.flush();
				expect(account2.is_closed).toBeTruthy();
			});
			
			it('should post reopen for given account and update closed flag on success when reopening', function() {
				$httpBackend.expectPOST('ledgers/ledger-332/accounts/a-2/reopen').respond(200);
				account2.is_closed = true;
				var result = scope.reopenAccount(account2);
				$httpBackend.flush();
				expect(account2.is_closed).toBeFalsy();
			});
			
			it('should DELETE destroy for given account and remove it from the service on success when removing', 
			inject(['accounts', '$location', function(accounts, $location) {
				spyOn(accounts, 'remove');
				spyOn($location, 'path');
				$httpBackend.expectDELETE('ledgers/ledger-332/accounts/a-2').respond(200);
				var result = scope.removeAccount(account2);
				$httpBackend.flush();
				expect(accounts.remove).toHaveBeenCalledWith(account2);
				expect($location.path).toHaveBeenCalledWith('/accounts');
			}]));
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
			
			it("should be loaded for active account", function() {
			    expect(scope.transactions).toBeUndefined();
				$httpBackend.flush();
				expect(scope.transactions.length).toEqual(transactions.length);
			});
			
			it("should not be loaded if active account", function() {
				this.assignActiveAccount(null);
				initController();
			    expect(scope.transactions).toBeUndefined();
				$httpBackend.flush();
				expect(scope.transactions).toBeUndefined();
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
	
	describe('getTransactionTypeIcon', function() {
		var filter;
		beforeEach(function() {
			transaction = {type_id: -100, is_transfer: false};
			inject(function(ttiFilter) { filter = ttiFilter});
		});
		it('should return transfer icon if transaction is transfer', function() {
			transaction.is_transfer = true;
			expect(filter(transaction)).toEqual('glyphicon glyphicon-transfer');
			expect(filter({type: Transaction.transferKey})).toEqual('glyphicon glyphicon-transfer');
		});
		it('should return income specific icon if transaction is income', function() {
			transaction.type_id = 1;
			expect(filter(transaction)).toEqual('glyphicon glyphicon-plus');
			expect(filter({type: Transaction.incomeKey})).toEqual('glyphicon glyphicon-plus');
		});
		it('should return expence specific icon if transaction is expence', function() {
			transaction.type_id = 2;
			expect(filter(transaction)).toEqual('glyphicon glyphicon-minus');
			expect(filter({type: Transaction.expenceKey})).toEqual('glyphicon glyphicon-minus');
		});
		it('should return refund specific icon if transaction is refund', function() {
			transaction.type_id = 3;
			expect(filter(transaction)).toEqual('glyphicon glyphicon-share-alt');
			expect(filter({type: Transaction.refundKey})).toEqual('glyphicon glyphicon-share-alt');
		});
	});
	
});
