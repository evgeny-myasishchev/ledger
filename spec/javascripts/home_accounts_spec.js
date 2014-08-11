describe("NewAccountController", function() {
	var controller, scope,  $httpBackend;
	beforeEach(function() {
		module('homeApp');
		inject(function(_$httpBackend_) {
			$httpBackend = _$httpBackend_;
		});
		HomeHelpers.include(this);
		this.assignActiveLedger({aggregate_id: 'ledger-332'});
	});
	
	function initController() {
		inject(function($rootScope, $controller) {
			scope = $rootScope.$new();
			controller = $controller('NewAccountController', {$scope: scope});
		});
	}

	it("initializes initial scope", function() {
		initController();
		expect(scope.newAccount).toEqual({
			name: null, currencyCode: null, initialBalance: '0'
		});
		expect(scope.currencies).toEqual([]);
	});
	
	describe('load new account data', function() {
		beforeEach(function() {
			$httpBackend.expectGET('ledgers/ledger-332/accounts/new.json').respond({
				new_account_id: 'new-account-332',
				currencies: [{c1: true}, {c2: true}]
			});
			initController();
			$httpBackend.flush();
		})
		
		it('should be loaded ledgers/ledger-332/accounts/new and assigned', function() {
			expect(scope.newAccount.newAccountId).toEqual('new-account-332');
			expect(scope.currencies).toEqual([{c1: true}, {c2: true}]);
		});
	});
	
	describe('report', function() {
		beforeEach(function() {
			$httpBackend.whenGET('ledgers/ledger-332/accounts/new.json').respond({new_account_id: '1', currencies: []});
			initController();
			$httpBackend.flush();
			scope.newAccount.newAccountId = 'account-223';
			scope.newAccount.name = 'New account';
			scope.newAccount.currencyCode = 'UAH';
			scope.newAccount.initialBalance = '0';
		});
		
		it('should POST ledger/accounts', function() {
			$httpBackend.expectPOST('ledgers/ledger-332/accounts', function(data) {
				var command = JSON.parse(data);
				expect(command.account_id).toEqual('account-223');
				expect(command.name).toEqual('New account');
				expect(command.currency_code).toEqual('UAH');
				expect(command.initial_balance).toEqual('0');
				return true;
			}).respond();
			scope.report();
			$httpBackend.flush();
		});
	});
});
