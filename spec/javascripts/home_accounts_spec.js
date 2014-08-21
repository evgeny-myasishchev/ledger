describe('home.acounts', function() {
	describe('accountsProvider', function() {
		var subject;
		var account1, account2, account3;
		var routeParams;
		beforeEach(function() {
			module('homeApp');
			homeApp.config(['accountsProvider', function(accountsProvider) {
				accountsProvider.assignAccounts([
					account1 = {aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000},
					account2 = {aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000},
					account3 = {aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200}
				]);
			}]);

			inject(function($routeParams) {
				routeParams = $routeParams;
			});
		});
		
		function initProvider() {
			inject(function($injector) {
				subject = $injector.get('accounts');
			});
		};
		
		it('should return all accounts on getAll', function() {
			initProvider();
			expect(subject.getAll()).toEqual([account1, account2, account3]);
		});

		it("should set active account from route params", function() {
			routeParams.accountSequentialNumber = account2.sequential_number;
			initProvider();
			expect(subject.getActive()).toEqual(account2);
		});

		it("should change active account if route params changed", function() {
			routeParams.accountSequentialNumber = account1.sequential_number;
			initProvider();
			routeParams.accountSequentialNumber = account2.sequential_number;
			expect(subject.getActive()).toEqual(account2);
		});
		
		it("should set first account as active if no accountId in params", function() {
			initProvider();
			expect(subject.getActive()).toEqual(account1);
		});
		
		it('should insert the account assigning sequential number on add', function() {
			initProvider();
			subject.add({aggregate_id: 'a4'});
			expect(subject.getAll()).toEqual([account1, account2, account3, {aggregate_id: 'a4', sequential_number: 204}]);
		});
		
		it('should remove the account on remove', function() {
			initProvider();
			var a4;
			subject.add(a4 = {aggregate_id: 'a4'});
			subject.remove(a4);
			expect(subject.getAll()).toEqual([account1, account2, account3]);
		});
	});
	
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
	
		describe('create', function() {
			var accounts;
			beforeEach(function() {
				$httpBackend.whenGET('ledgers/ledger-332/accounts/new.json').respond({new_account_id: '1', currencies: []});
				initController();
				$httpBackend.flush();
				scope.newAccount.newAccountId = 'account-223';
				scope.newAccount.name = 'New account';
				scope.newAccount.currencyCode = 'UAH';
				scope.newAccount.initialBalance = '2332.31';
				inject(['accounts', function(a) { accounts = a;}]);
				spyOn(accounts, 'add');
			});
		
			it('should POST ledger/accounts setting progress flags', function() {
				$httpBackend.expectPOST('ledgers/ledger-332/accounts', function(data) {
					var command = JSON.parse(data);
					expect(command.account_id).toEqual('account-223');
					expect(command.name).toEqual('New account');
					expect(command.currency_code).toEqual('UAH');
					expect(command.initial_balance).toEqual('2332.31');
					return true;
				}).respond();
				expect(scope.created).toBeFalsy();
				expect(scope.creating).toBeFalsy();
				scope.create();
				expect(scope.creating).toBeTruthy();
				$httpBackend.flush();
				expect(scope.creating).toBeFalsy();
				expect(scope.created).toBeTruthy();
			});
		
			it('should add the account on success', function() {
				$httpBackend.whenPOST('ledgers/ledger-332/accounts').respond();
				scope.create();
				$httpBackend.flush();
				expect(accounts.add).toHaveBeenCalledWith({aggregate_id: 'account-223', name: 'New account', currency_code: 'UAH', balance: 233231, is_closed: false})
			});
		});
	
		describe('createAnother', function() {
			beforeEach(function() {
				$httpBackend.whenGET('ledgers/ledger-332/accounts/new.json').respond({ new_account_id: 'new-account-332', currencies: [] });
				initController();
				$httpBackend.flush();
			});
		
			it('should load and assign new account data', function() {
				$httpBackend.expectGET('ledgers/ledger-332/accounts/new.json').respond({ new_account_id: 'new-account-333', currencies: [] });
				scope.createAnother();
				$httpBackend.flush();
				expect(scope.newAccount.newAccountId).toEqual('new-account-333');
			});
		
			it('should reset progress flags on success', function() {
				scope.created = true;
				scope.createAnother();
				$httpBackend.flush();
				expect(scope.created).toBeFalsy();
			});
		
			it('should reset new account data on success', function() {
				scope.newAccount.name = 'Some name';
				scope.newAccount.currencyCode = 'UAH';
				scope.newAccount.initialBalance = '2200.30';
				scope.createAnother();
				$httpBackend.flush();
				expect(scope.newAccount.name).toBeNull();
				expect(scope.newAccount.currencyCode).toBeNull();
				expect(scope.newAccount.initialBalance).toEqual('0');
			});
		});
	});
});