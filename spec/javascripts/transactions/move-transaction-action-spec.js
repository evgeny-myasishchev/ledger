describe('transactions.moveTransactionAction', function() {
	var outerScope, scope, $httpBackend, $compile;
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
		outerScope = $rootScope.$new();
		outerScope.transaction = {
			transaction_id: 't-432',
			account_id: account1.aggregate_id
		}
		$compile = _$compile_;
	}));
	
	function compile() {
		var elem = angular.element('<div class="btn-group"><button move-transaction-action transaction="transaction"></button></div>');
		var compiledElem = $compile(elem)(outerScope);
		outerScope.$digest();
		var button = compiledElem.find('button');
		scope = button.isolateScope();
		return button;
	};
	
	describe('data attribute', function() {
		it('should assign accounts on element click', function() {
			var element = compile();
			element.click();
			expect(scope.accounts).toEqual([account1, account2]);
		});
		
		it('should assign account that should not be moved to for regular transactions', function() {
			var element = compile();
			element.click();
			expect(scope.dontMoveTo).toEqual(account1);
		});
		
		it('should assign accounts that should not be moved to for transfer transactions', function() {
			outerScope.transaction.is_transfer = true;
			outerScope.transaction.sending_account_id = account1.aggregate_id;
			outerScope.transaction.receiving_account_id = account2.aggregate_id;
			var element = compile();
			element.click();
			expect(scope.dontMoveTo).toEqual([account1, account2]);
		});
		
		it('should clear target account on element click', function() {
			var element = compile();
			scope.targetAccount = account2;
			element.click();
			expect(scope.accounts).toEqual([account1, account2]);
			expect(scope.targetAccount).toBeNull();
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