describe('transactions.newTransactionDetails directive', function() {
	var scope, $httpBackend, $compile;
	var account1, account2;
	
	beforeEach(module('transactionsApp'));
	
	beforeEach(inject(function(_$httpBackend_, _$compile_, $rootScope){
		$httpBackend = _$httpBackend_;
		scope = $rootScope.$new();
		$compile = _$compile_;
		
		angular.module('transactionsApp').config(['accountsProvider', function(accountsProvider) {
			accountsProvider.assignAccounts([
				account1 = {aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, category_id: 1, is_closed: false},
				account2 = {aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, category_id: 2, is_closed: false}
			]);
		}]);
	}));
	
	function compile() {
		var elem = angular.element('<div><script type="text/ng-template" id="new-transaction-details.html"></script>' +
			'<new-transaction-details transaction="transaction"></new-transaction-details></div>');
		var compiledElem = $compile(elem)(scope);
		scope.$digest();
		return compiledElem;
	};
	
	describe('transaction.amount changes', function() {
		beforeEach(function() {
			scope.transaction = {
				type_id: null, amount: null
			};
			compile();
		});
		
		it('should set transaction type to income if amount is signed and positive', function() {
			scope.transaction.amount = "+1000";
			scope.$digest();
			expect(scope.transaction.type_id).toEqual(Transaction.incomeId);
		});
		
		it('should set transaction type to expense if amount is signed and negative', function() {
			scope.transaction.amount = "-1000";
			scope.$digest();
			expect(scope.transaction.type_id).toEqual(Transaction.expenseId);
		});
		
		it('should do nothing if amount has no sign', function() {
			scope.transaction.amount = "1000";
			scope.$digest();
			expect(scope.transaction.type_id).toBeNull();
		});
	});
});