describe('home.accountsPanel', function() {
	var scope, accounts;
	var account1, account2, account3;
	var controller, scope,  $httpBackend;
	var category1, category2;
	var routeParams;
	beforeEach(function() {
		module('homeApp');
		angular.module('homeApp').config(['accountsProvider', function(accountsProvider) {
			accountsProvider.assignAccounts([
				account1 = {aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000},
				account2 = {aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000},
				account3 = {aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200}
			]);
			accountsProvider.assignCategories([
				category1 = {id: 1, display_order: 1, name: 'Category 1'},
				category2 = {id: 1, display_order: 2, name: 'Category 2'}
			]);
		}]);
		inject(['$httpBackend', 'accounts', function(_$httpBackend_, a) {
			$httpBackend = _$httpBackend_;
			accounts = a;
		}]);
	});

	function compile() {
		var result;
		inject(function($rootScope, $compile) {
			scope = $rootScope.$new();
			result = $compile('<script type="text/ng-template" id="accounts-panel.html">' +
			'<div id="accounts-panel"></div>' +
			'</script>' +
			'<accounts-panel></accounts-panel>' +
			'')(scope);
		});
		scope.$digest();
		return result;
	};

	it('should assign accounts', function() {
		compile();
		expect(scope.accounts).toEqual([account1, account2, account3]);
	});

	it('should assign categories', function() {
		compile();
		expect(scope.categories).toEqual([category1, category2]);
	});

	it('should determine if there are closed accounts with hasClosedAccounts method', function() {
		compile();
		scope.accounts = [{is_closed: false}, {is_closed: false}];
		expect(scope.hasClosedAccounts()).toBeFalsy();
		scope.accounts = [{is_closed: false}, {is_closed: false}, {is_closed: true}];
		expect(scope.hasClosedAccounts()).toBeTruthy();
	});

	it('should toggle showClosed flag using accountsState', inject(['accountsState', function(accountsState) {
		compile();
		scope.showClosed = true;
		spyOn(accountsState, 'showingClosed').and.returnValue(false);
		scope.toggleShowClosedAccounts();
		expect(scope.showClosed).toBeFalsy();
		expect(accountsState.showingClosed).toHaveBeenCalledWith(false);
	}]));
});