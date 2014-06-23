describe("HomeController", function() {
	beforeEach(module('ledgerApp'));
	
	it("should have default accounts", inject(function($controller) {
		var scope = {};
		var controller = $controller('HomeController', {$scope: scope});
		expect(scope.accounts.length).toEqual(3);
	}));
});