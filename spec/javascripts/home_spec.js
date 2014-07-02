describe("homeApp", function() {
	var account1, account2, account3;
	var controller, scope;
	beforeEach(function() {
		module('homeApp');
		scope = {};
		homeApp.constant('accounts',  [
			account1 = {id: 1, 'name': 'Cache UAH', 'balance': '100 UAH'},
			account2 = {id: 2, 'name': 'PC Credit J', 'balance': '200 UAH'},
			account3 = {id: 3, 'name': 'VAB Visa', 'balance': '4432 UAH'}
		]);
	});
	
	describe('AccountsController', function() {
		var routeParams, $httpBackend;
		beforeEach(function() {
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
		
		it("should set active account from route params", function() {
			routeParams.accountId = account2.id;
			initController();
			expect(scope.activeAccount).toEqual(account2);
		});
		
		it("should set first account as active if no accountId in params", function() {
			initController();
			expect(scope.activeAccount).toEqual(account1);
		});
		
		it("should get the transactions for active account from the server", function() {
			var transactions = [
				{transaction1: true},
				{transaction2: true}
			];
			$httpBackend.expectGET('accounts/1/transactions.json').respond(transactions);
			initController();
		    expect(scope.transactions).toBeUndefined();
			$httpBackend.flush();
			expect(scope.transactions).toEqual(transactions);
		});
	});
});
