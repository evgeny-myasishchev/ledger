describe("HomeController", function() {
	beforeEach(function() {
		module('ledgerApp');
		ledgerApp.constant('accounts',  [
			{'name': 'Cache UAH', 'balance': '100 UAH'},
			{'name': 'PC Credit J', 'balance': '200 UAH'},
			{'name': 'VAB Visa', 'balance': '4432 UAH'}
		]);
	});
	
	
	it("should have default accounts", inject(function($controller) {
		var scope = {};
		var controller = $controller('HomeController', {$scope: scope});
		expect(scope.accounts.length).toEqual(3);
	}));
});