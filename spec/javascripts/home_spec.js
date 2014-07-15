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
			expect(scope.newTransaction).toEqual({
				ammount: null, tags: null, type: 'expence', date: new Date().toLocaleDateString(), comment: null
			});
		});
		
		describe("report", function() {
			var date;
			beforeEach(function() {
				date = new Date().toLocaleDateString();
				initController();
				scope.newTransaction.ammount = '10.5';
				scope.newTransaction.tags = null;
				scope.newTransaction.date = date;
				scope.newTransaction.comment = 'New transaction 10.5';
			});
			
			it("should submit the new income transaction", function() {
				scope.newTransaction.type = 'income';
				$httpBackend.expectPOST('accounts/a-1/transactions/report-income', {
					command: {
						ammount: '10.5', tags: null, date: date, comment: 'New transaction 10.5'
					}
				}).respond();
				scope.report();
				$httpBackend.flush();
			});
			
			it("should submit the new expence transaction", function() {
				scope.newTransaction.type = 'expence';
				$httpBackend.expectPOST('accounts/a-1/transactions/report-expence', {
					command: {
						ammount: '10.5', tags: null, date: date, comment: 'New transaction 10.5'
					}
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
						ammount: '10.5', tags: null, type: 'expence', date: date, comment: 'New transaction 10.5'
					});
				});
				
				it('should reset the newTransaction model', function() {
					expect(scope.newTransaction).toEqual({
						ammount: null, tags: null, type: 'expence', date: new Date().toLocaleDateString(), comment: null
					});
				});
			});
		});
	});
});
