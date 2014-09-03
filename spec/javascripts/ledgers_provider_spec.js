describe("ledgersProvider", function() {
	var ledgersProvider, subject, $httpBackend;
	beforeEach(function() {
		module('ledgersProvider');
		angular.module('ledgersProvider').config(['ledgersProvider', function(provider) {
			ledgersProvider = provider;
		}]);
		inject(function(ledgers, _$httpBackend_) { 
			$httpBackend = _$httpBackend_;
			subject = ledgers; 
		});
	});
	
	it('should return first ledger on getActiveLedger', function() {
		var l1;
		ledgersProvider.assignLedgers([
			l1 = {id: 'l-1'}, {id: 'l-2'}, {id: 'l-3'}
		]);
		expect(subject.getActiveLedger()).toEqual(l1);
	});
	
	describe('loadCurrencyRates', function() {
		var rate1, rate2;
		beforeEach(function() {
			var activeLedger;
			ledgersProvider.assignLedgers([
				activeLedger = {aggregate_id: 'l-1'}, {aggregate_id: 'l-2'}
			]);
			rate1 = {"id":14,"from":"EUR","to":"UAH","rate":16.1344};
			rate2 = {"id":13,"from":"USD","to":"UAH","rate":12.2854};
		});
		
		it('should load currency rates for active ledger and hash loaded rates by from', function() {
			$httpBackend.expectGET('ledgers/l-1/currency-rates.json').respond(200, JSON.stringify([rate1, rate2]));
			var loadedRates;
			subject.loadCurrencyRates().then(function(result) {
				loadedRates = result;
			});
			$httpBackend.flush();
			expect(loadedRates).toBeDefined();
			expect(loadedRates[rate1.from]).toEqual(rate1);
			expect(loadedRates[rate2.from]).toEqual(rate2);
		});
		
		it('should cache loaded rates', function() {
			$httpBackend.expectGET('ledgers/l-1/currency-rates.json').respond(200, JSON.stringify([rate1, rate2]));
			
			subject.loadCurrencyRates();
			$httpBackend.flush();
			
			var loadedRates;
			subject.loadCurrencyRates().then(function(result) {
				loadedRates = result;
			});
			$httpBackend.verifyNoOutstandingExpectation();
			expect(loadedRates).toBeDefined();
			expect(loadedRates[rate1.from]).toEqual(rate1);
			expect(loadedRates[rate2.from]).toEqual(rate2);
		});
	});
});