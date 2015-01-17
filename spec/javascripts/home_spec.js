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

		describe('set-category/close/reopen/remove account', function() {
			beforeEach(function() {
				$httpBackend.whenGET('accounts/a-1/transactions.json').respond({ transactions: [] });
				initController();
				$httpBackend.flush();
				HomeHelpers.include(this);
				this.assignActiveLedger({aggregate_id: 'ledger-332'});
			});

			it('should put set-category for given account and update category_id on success', function() {
				$httpBackend.expectPUT('ledgers/ledger-332/accounts/a-2/set-category', function(data) {
					expect(JSON.parse(data).category_id).toEqual(332);
					return true;
				}).respond(200);
				var result = scope.setAccountCategory(account2, 332);
				$httpBackend.flush();
				expect(account2.category_id).toEqual(332);
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

			it("should be loaded for all accounts", function() {
				this.assignActiveAccount(null);
				initController();
			    expect(scope.transactions).toBeUndefined();
				$httpBackend.expectGET('transactions.json').respond({
					transactions_total: 4432,
					transactions_limit: 25,
					transactions: transactions
				});
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
					$httpBackend.whenPOST('accounts/a-1/transactions/10-20.json').respond({transactions: transactions});
					spyOn(scope, 'refreshRangeState');
					scope.transactionsInfo.limit = 10;
					scope.fetch(10);
					$httpBackend.flush();
				});
				
				it('should get transactions range for given account and given offset', function() {
					expect(scope.transactions.length).toEqual(transactions.length);
				});
				
				it('should get transactions range for all accounts and given offset', function() {
					this.assignActiveAccount(null);
					$httpBackend.whenGET('transactions.json').respond({transactions: []});
					$httpBackend.whenPOST('transactions/10-20.json').respond({transactions: transactions});
					initController();
					scope.transactionsInfo = {limit: 10};
					scope.fetch(10);
					$httpBackend.flush();
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

				it('should post with search criteria if provided', function() {
					scope.searchCriteria.criteria = {'key1': 'vlaue-1', 'key2': 'vlaue-2'};
					$httpBackend.expectPOST('accounts/a-1/transactions/10-20.json', function(postBody) {
						var data = JSON.parse(postBody);
						expect(data['criteria']).toEqual(scope.searchCriteria.criteria);
						return true;
					}).respond({transactions: transactions});
					scope.fetch(10);
					$httpBackend.flush();
				});

				it('should update total if special option provided', function() {
					$httpBackend.expectPOST('accounts/a-1/transactions/0-10.json', function(postBody) {
						var data = JSON.parse(postBody);
						expect(data['with-total']).toBeTruthy();
						return true;
					}).respond({transactions: transactions, transactions_total: 22332});
					scope.transactionsInfo.total = 200;
					scope.fetch(0, {updateTotal: true});
					$httpBackend.flush();
					expect(scope.transactionsInfo.total).toEqual(22332);
				});
			});
		});

		describe('search', function() {
			var search;
			beforeEach(inject(['search', function(s) {
				$httpBackend.whenGET('accounts/a-1/transactions.json').respond({transactions: []});
				initController();
				$httpBackend.flush();
				search = s;
			}]));

			it('should use search provdier and parse the expression', function() {
				scope.searchCriteria.expression = 'Search expression';
				spyOn(search, 'parseExpression').and.returnValue({key1: 'value1'});
				scope.search();
				expect(search.parseExpression).toHaveBeenCalledWith('Search expression');
				expect(scope.searchCriteria.criteria).toEqual({key1: 'value1'});
			});

			it('should set the criteria to null if expression is null or empty', function() {
				scope.searchCriteria.criteria = {key1: 'value1'};
				scope.searchCriteria.expression = '';
				scope.search();
				expect(scope.searchCriteria.criteria).toBeNull();

				scope.searchCriteria.criteria = {key1: 'value1'};
				scope.searchCriteria.expression = null;
				scope.search();
				expect(scope.searchCriteria.criteria).toBeNull();
			});

			it('should fetch with zero offset', function() {
				scope.transactionsInfo.offset = 100;
				spyOn(scope, 'fetch');
				scope.search();
				expect(scope.fetch).toHaveBeenCalledWith(0, {updateTotal: true});
			});
		});
	});
});
