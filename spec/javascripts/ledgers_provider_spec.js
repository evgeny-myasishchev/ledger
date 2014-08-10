describe("ledgersProvider", function() {
	var ledgersProvider, subject;
	beforeEach(function() {
		module('ledgersProvider');
		angular.module('ledgersProvider').config(['ledgersProvider', function(provider) {
			ledgersProvider = provider;
		}]);
		inject(function(ledgers) { subject = ledgers; });
	});
	
	it('should return first ledger on getActiveLedger', function() {
		var l1;
		ledgersProvider.assignLedgers([
			l1 = {id: 'l-1'}, {id: 'l-2'}, {id: 'l-3'}
		]);
		expect(subject.getActiveLedger()).toEqual(l1);
	});
});