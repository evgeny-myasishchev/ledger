describe('transactions.moveTransactionAction', function() {
	var scope, $httpBackend, $compile;
	var account1, account2;
	
	beforeEach(function() {
		module('transactionsApp');
		angular.module('transactionsApp').config(['accountsProvider', function(accountsProvider) {
			accountsProvider.assignAccounts([
				account1 = {aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, category_id: 1, is_closed: false},
				account2 = {aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, category_id: 2, is_closed: false}
			]);
		}]);
	});
	
	beforeEach(inject(function(_$httpBackend_, _$compile_, $rootScope){
		$httpBackend = _$httpBackend_;
		scope = $rootScope.$new();
		scope.transaction = {
			transaction_id: 't-432'
		}
		$compile = _$compile_;
	}));
	
	function compile() {
		var elem = angular.element('<button move-transaction-action></button');
		var compiledElem = $compile(elem)(scope);
		scope.$digest();
		return compiledElem;
	};
	
	describe('data attribute', function() {
		it('should assign accounts on element click', function() {
			var element = compile();
			element.click();
			expect(scope.accounts).toEqual([account1, account2]);
		});
	});
	
	describe('move', function() {
		var provider;
		beforeEach(inject(['transactions', function(transactionsProvider) {
			provider = transactionsProvider;
			compile();
		}]));
		
		it('should delegate to transactions provider', function() {
			scope.targetAccount = account2;
			spyOn(provider, 'moveTo').and.returnValue(jQuery.Deferred().promise());
			scope.move();
			expect(provider.moveTo).toHaveBeenCalledWith(scope.transaction, account2);
		});
	});
});