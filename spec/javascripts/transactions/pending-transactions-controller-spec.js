describe('transactions.PendingTransactionsController', function() {
	var scope, $httpBackend, pendingTransactions, subject;
	
	beforeEach(module('transactionsApp'));
	
	beforeEach(inject(function(_$httpBackend_, $rootScope, _pendingTransactions_){
		$httpBackend = _$httpBackend_;
		pendingTransactions = _pendingTransactions_;
	}));
	
	function initController() {
		inject(function($rootScope, $controller) {
			scope = $rootScope.$new();
			subject = $controller('PendingTransactionsController', {$scope: scope});
		});
	};
	
	it('should fetch pending transactions', function() {
		$httpBackend.expectGET('pending-transactions.json').respond(
			[{t1: true}, {t2: true}, {t3: true}]
		);
		initController();
		$httpBackend.flush();
		expect(scope.transactions).toEqual([{t1: true}, {t2: true}, {t3: true}]);
	});
	
	it("should have dates converted to date object", function() {
		date = new Date();
		$httpBackend.expectGET('pending-transactions.json').respond(
			[{t1: true, date: date.toJSON()}, {t2: true, date: date.toJSON()}, {t3: true, date: date.toJSON()}]
		);
		initController();
		$httpBackend.flush();
		jQuery.each(scope.transactions, function(i, t) {
			expect(t.date).toEqual(date);
		});
	});
});