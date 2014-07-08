describe("homeApp", function() {
	var account1, account2, account3;
	var controller, scope;
	beforeEach(function() {
		module('homeApp');
		scope = {};
		homeApp.constant('accounts',  [
			account1 = {id: 1, aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': '100 UAH'},
			account2 = {id: 2, aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': '200 UAH'},
			account3 = {id: 3, aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': '4432 UAH'}
		]);
	});

	describe('activeAccountAccessor', function() {
		var routeParams, accessor;
		beforeEach(function() {
			inject(function($routeParams) {
				routeParams = $routeParams;
			});
		});
		
		function initAccessor() {
			inject(function($injector) {
				accessor = $injector.get('activeAccountAccessor');
			});
		}

		it("should set active account from route params", function() {
			routeParams.accountSequentialNumber = account2.sequential_number;
			initAccessor();
			expect(accessor.get()).toEqual(account2);
		});

		it("should change active account if route params changed", function() {
			routeParams.accountSequentialNumber = account1.sequential_number;
			initAccessor();
			routeParams.accountSequentialNumber = account2.sequential_number;
			expect(accessor.get()).toEqual(account2);
		});
		
		it("should set first account as active if no accountId in params", function() {
			initAccessor();
			expect(accessor.get()).toEqual(account1);
		});
	});
	
	describe('AccountsController', function() {
		var routeParams, $httpBackend;
		beforeEach(function() {
			inject(function(activeAccountAccessor) {
				activeAccountAccessor.set(account1);
			});
			inject(function(_$httpBackend_) {
				$httpBackend = _$httpBackend_;
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
			inject(function(activeAccountAccessor) {
				activeAccountAccessor.set(account2);
			});
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
			inject(function(activeAccountAccessor) {
				activeAccountAccessor.set(activeAccount);
			});
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
	});
});
