describe('accounts.actualBalanceTip directive', function() {
	var a1, a2, a3, all, rates;
	var accounts, scope;
	
	beforeEach(function() {
		module('homeApp');
		a1 = {balance: 10000, currency_code: 'EUR'};
		a2 = {balance: 20000, currency_code: 'USD'};
		a3 = {balance: 30000, currency_code: 'UAH'};
		all = [a1, a2, a3];

		inject(['$rootScope', 'ledgers', 'accounts', function($rootScope, ledgers, a) {
			accounts = a;
			scope = $rootScope.$new();
			var deferredCurrencyRates = $.Deferred();
			deferredCurrencyRates.resolve(rates = {
				EUR: {"id":14,"from":"EUR","to":"UAH","rate":16.22},
				USD: {"id":13,"from":"USD","to":"UAH","rate":12.93}
			});
			spyOn(ledgers, 'getActiveLedger').and.returnValue({aggregate_id: 'l-1', currency_code: 'UAH'});
			spyOn(ledgers, 'loadCurrencyRates').and.returnValue(deferredCurrencyRates.promise());
		}]);
		spyOn(accounts, 'getActualBalance').and.callFake(function(account, rates) {
			return account.balance;
		});
	});

	function compile() {
		var result;
		inject(function($compile) {
			result = $compile('<span actual-balance-tip>')(scope);
		});
		scope.$digest();
		return jQuery(result[0]);
	};
	
	it('should add tooltip if the account has a different currency than active ledger', function() {
		scope.account = a1;
		var element = compile();
		expect(element.attr('title')).toEqual('100.00 UAH (1 EUR = 16.22 UAH)');
		
		scope.account = a2;
		var element = compile();
		expect(element.attr('title')).toEqual('200.00 UAH (1 USD = 12.93 UAH)');
	});
	
	it('should calculate the rate if the account has unit', function() {
		a1.unit = 'g';
		accounts.getActualBalance.and.callFake(function(account, rates) {
			return 84332;
		});	
		scope.account = a1;
		var element = compile();
		expect(element.attr('title')).toEqual('843.32 UAH (1g. EUR = 8.4332 UAH)');
	});
	
	it('should not add the tooltip if the account has same currency as active ledger', function() {
		scope.account = a3;
		var element = compile();
		expect(element.attr('title')).toBeUndefined();
	});
		
	it('should not add the tooltip if the account is XXX', function() {
		a3.currency_code = 'XXX';
		scope.account = a3;
		var element = compile();
		expect(element.attr('title')).toBeUndefined();
	});
});