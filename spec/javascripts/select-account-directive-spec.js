describe('acounts', function() {
	describe('selectAccount directive', function() {
		var account1, account2, account3, account4;
		var $compile, scope, outerScope;
		beforeEach(function() {
			module('accountsApp');
			accountsApp.config(['accountsProvider', function(accountsProvider) {
				accountsProvider.assignAccounts([
					account1 = {aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, category_id: 1, is_closed: false},
					account2 = {aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, category_id: 2, is_closed: false},
					account3 = {aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200, category_id: null, is_closed: false}
				]);
			}]);
			
			inject(function($rootScope, _$compile_) {
				$compile = _$compile_;
				outerScope = $rootScope.$new();
			});
		});
		
		function compile(html) {
			html = html ? html : '<select-account></select-account>';
			var compiledElem = $compile(html)(outerScope);
			outerScope.$digest();
			scope = compiledElem.isolateScope();
			return compiledElem;
		};
		
		it('should assign accounts', function() {
			compile();
			expect(scope.accounts).toEqual([account1, account2, account3]);
		});
		
		describe('filterAccount', function() {
			it('should filter out closed accounts', function() {
				account1.is_closed = true;
				account2.is_closed = true;
				compile();
				expect(scope.filterAccount(account1)).toBeFalsy();
				expect(scope.filterAccount(account2)).toBeFalsy();
				expect(scope.filterAccount(account3)).toBeTruthy();
			});
			
			it('should return true if no except provided', function() {
				compile();
				expect(scope.filterAccount(account1)).toBeTruthy();
				expect(scope.filterAccount(account2)).toBeTruthy();
				expect(scope.filterAccount(account3)).toBeTruthy();
			});
			
			it('should return false if except account provided', function() {
				outerScope.otherAccount = account2;
				compile('<select-account except="otherAccount"></select-account>');
				expect(scope.filterAccount(account1)).toBeTruthy();
				expect(scope.filterAccount(account2)).toBeFalsy();
				expect(scope.filterAccount(account3)).toBeTruthy(true);
			});
			
			it('should return false if multiple except accounts provided', function() {
				outerScope.exceptAccounts = [account1, account2];
				compile('<select-account except="exceptAccounts"></select-account>');
				expect(scope.filterAccount(account1)).toBeFalsy();
				expect(scope.filterAccount(account2)).toBeFalsy();
				expect(scope.filterAccount(account3)).toBeTruthy();
			});
		});
	})
});