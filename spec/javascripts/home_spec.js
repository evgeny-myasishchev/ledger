describe("HomeController", function() {
	var account1, account2, account3;
	var controller, scope;
	beforeEach(function() {
		module('ledgerApp');
		ledgerApp.constant('accounts',  [
			account1 = {id: 1, 'name': 'Cache UAH', 'balance': '100 UAH'},
			account2 = {id: 2, 'name': 'PC Credit J', 'balance': '200 UAH'},
			account3 = {id: 3, 'name': 'VAB Visa', 'balance': '4432 UAH'}
		]);
		inject(function($controller) {
			scope = {};
			controller = $controller('HomeController', {$scope: scope});
		});
	});
	
	it("should have default accounts", function() {
		expect(scope.accounts.length).toEqual(3);
	});
	
	describe("selectAccount", function() {
		beforeEach(function() {
			scope.selectAccount(account1);
		});
		
		it("should assign activeAccount into the scope", function() {
			expect(scope.activeAccount).toEqual(account1);
		});
	});
	
	describe('isActive', function() {
		it('should determine if the account is active', function() {
			expect(scope.isActive(account1)).toBeFalsy();
			scope.activeAccount = account1;
			expect(scope.isActive(account1)).toBeTruthy();
		});
	});
});