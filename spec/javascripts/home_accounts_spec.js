describe('home.acounts', function() {
	describe('accountsProvider', function() {
		var subject;
		var account1, account2, account3, account4;
		var category1, category2;
		var routeParams;
		beforeEach(function() {
			module('homeApp');
			homeApp.config(['accountsProvider', function(accountsProvider) {
				accountsProvider.assignAccounts([
					account1 = {aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, category_id: 1, is_closed: false},
					account2 = {aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, category_id: 2, is_closed: false},
					account3 = {aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200, category_id: null, is_closed: false},
					account4 = {aggregate_id: 'a-4', sequential_number: 204, 'name': 'Cache USD', 'balance': 754, category_id: null, is_closed: false}
				]);
				accountsProvider.assignCategories([
					category1 = {id: 1, display_order: 1, name: 'Category 1'},
					category2 = {id: 2, display_order: 2, name: 'Category 2'}
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
			expect(subject.getAll()).toEqual([account1, account2, account3, account4]);
		});
		
		it('should return all open accounts on getAllOpen', function() {
			account3.is_closed = true;
			account4.is_closed = true;
			initProvider();
			expect(subject.getAllOpen()).toEqual([account1, account2]);
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
		
		it("should return null if no account info in route params", function() {
			initProvider();
			expect(subject.getActive()).toBeNull();
		});
		
		describe('add', function() {
			var $rootScope;
			beforeEach(inject(['$rootScope', function(rs) {
				$rootScope = rs;
			}]));
			it('should insert the account assigning sequential number', function() {
				initProvider();
				subject.add({aggregate_id: 'a4'});
				expect(subject.getAll()).toEqual([account1, account2, account3, account4, {aggregate_id: 'a4', sequential_number: 205, category_id: null}]);
			});
			
			it('should broadcast account-added event', function() {
				var accountAdded = jasmine.createSpy('account-added');
				$rootScope.$on('account-added', accountAdded);
				initProvider();
				var account;
				subject.add(account = {aggregate_id: 'a4'});
				expect(accountAdded).toHaveBeenCalledWith(jasmine.any(Object), account);
			});
		});
		
		it('should remove the account on remove', function() {
			initProvider();
			var a4;
			subject.add(a4 = {aggregate_id: 'a4'});
			subject.remove(a4);
			expect(subject.getAll()).toEqual([account1, account2, account3, account4]);
		});
		
		describe('categories', function() {
			beforeEach(function() {
				initProvider();
			});
			
			it('should return all categories on getAllCategories', function() {
				expect(subject.getAllCategories()).toEqual([category1, category2]);
			});
			
			it('should insert new category on addCategory', function() {
				var all = subject.getAllCategories();
				subject.addCategory(110, 'New category 110');
				expect(all).toEqual([category1, category2, {category_id: 110, display_order: 3, name: 'New category 110'}]);
			});
			
			it('should remove the category on removeCategory', function() {
				subject.removeCategory(category1);
				expect(subject.getAllCategories()).toEqual([category2]);
				subject.removeCategory(category2);
				expect(subject.getAllCategories()).toEqual([]);
			});
		});
		
		describe('getActualBalance', function() {
			var subject, rates;
			beforeEach(function() {
				account1.currency = {
					id: 980, code: 'UAH'
				};
				inject(['accounts', 'ledgers', function(accounts, ledgers) {
					rates = {
						EUR: {"id":14,"from":"EUR","to":"UAH","rate":16.22},
						USD: {"id":13,"from":"USD","to":"UAH","rate":12.93}
					};
					subject = accounts;
					spyOn(ledgers, 'getActiveLedger').and.returnValue({aggregate_id: 'l-1', currency_code: 'UAH'});
					account1.currency_code = 'UAH';
				}]);
			});
			
			it('should return the balance as is if curency_code is same as ledger has', function() {
				expect(subject.getActualBalance(account1, rates)).toEqual(account1.balance);
			});
			
			it('should convert the balance using units service if account unit is different from currency', inject(['units', function(units) {
				spyOn(units, 'convert').and.returnValue(332223);
				account1.currency.unit = 'unit-1';
				account1.unit = 'unit-2';
				expect(subject.getActualBalance(account1, rates)).toEqual(332223);
				expect(units.convert).toHaveBeenCalledWith('unit-2', 'unit-1', account1.balance);
			}]));
			
			it('should multiply the balance by rate if ledger currency is different', function() {
				account1.currency_code = 'EUR';
				account1.balance = 10044;
				var result = subject.getActualBalance(account1, rates);
				expect(result).toEqual(162913);
			});
		})
	});
	
	describe('calculateTotalFilter', function() {
		var a1, a2, a3, all, rates;
		var accounts;
		var scope;
		beforeEach(function() {
			module('homeApp');
			a1 = {balance: 10000, currency_code: 'UAH'};
			a2 = {balance: 20000, currency_code: 'UAH'};
			a3 = {balance: 30000, currency_code: 'UAH'};
			all = [a1, a2, a3];
			
			inject(['$rootScope', 'calculateTotalFilter', 'ledgers', 'accounts', function($rootScope, theFilter, ledgers, a) {
				accounts = a;
				scope = $rootScope.$new();
				scope.filter = theFilter;
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
		
		it('should return supplied accounts', function() {
			expect(scope.filter(all, 'result')).toEqual(all);
		});
		
		it('should operate with actual balance using accounts', function() {
			expect(scope.filter(all, 'result')).toEqual(all);
			expect(accounts.getActualBalance).toHaveBeenCalledWith(a1, rates);
			expect(accounts.getActualBalance).toHaveBeenCalledWith(a2, rates);
			expect(accounts.getActualBalance).toHaveBeenCalledWith(a3, rates);
		});
		
		it('should assign summary of all balances to given variable', function() {
			scope.filter(all, 'result');
			scope.$digest();
			expect(scope.result).toEqual(60000);
		});
		
		it('should not calculate if rate for the account is not present', function() {
			accounts.getActualBalance.and.callFake(function(account) {
				if(account == a3) return a3.balance;
				return null;
			});
			a1.currency_code = 'GBP';
			a2.currency_code = 'GBP';
			scope.filter(all, 'result');
			scope.$digest();
			expect(scope.result).toEqual(30000);
		});
	});
	
	describe('activateFirstAccountFilter', function() {
		var a1, a2;
		var location, accounts;
		var subject;
		beforeEach(function() {
			module('homeApp');
			a1 = {balance: 10000, currency_code: 'UAH'};
			a2 = {balance: 20000, currency_code: 'UAH'};
			
			inject(['$location', 'activateFirstAccountFilter', 'accounts', function(theLocation, filter, theAccounts) {
				location = theLocation;
				accounts = theAccounts;
				subject = filter;
			}]);
			spyOn(accounts, 'getActive').and.returnValue(null);
			spyOn(accounts, 'makeActive').and.throwError('makeActive should not be called');
		});
		
		it('should return the account if there is active account', function() {
			accounts.getActive.and.returnValue(a2);
			expect(subject(a1)).toBe(a1);
		});
		
		it('should return the account if the path corresponds to actual path of some account', function() {
			location.$$path = '/accounts/100';
			expect(subject(a1)).toBe(a1);
			location.$$path = '/accounts/100/report';
			expect(subject(a1)).toBe(a1);
		});
		
		it('should make the account active and return it', function() {
			accounts.makeActive.and.returnValue(null);
			expect(subject(a1)).toBe(a1);
			expect(accounts.makeActive).toHaveBeenCalledWith(a1);
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
				name: null, currency: null, initialBalance: '0', unit: null
			});
			expect(scope.currencies).toEqual([]);
		});
		
		it('should watch newAccount currency changes and set default unit of oz if currency unit is oz', function() {
			$httpBackend.whenGET('ledgers/ledger-332/accounts/new.json').respond({
				new_account_id: 'new-account-332',
				currencies: [{c1: true}, {c2: true}]
			});
			initController();
			scope.newAccount.currency = {code: 'XAU', unit: 'oz'};
			scope.$digest();
			expect(scope.newAccount.unit).toEqual('oz');

			scope.newAccount.currency = {code: 'UAH'};
			scope.$digest();
			expect(scope.newAccount.unit).toBeNull();
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
				scope.newAccount.currency = {code: 'UAH'};
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
					expect(command.unit).toBeUndefined();
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
			
			it('should include unit if specified', function() {
				$httpBackend.expectPOST('ledgers/ledger-332/accounts', function(data) {
					var command = JSON.parse(data);
					expect(command.unit).toEqual('oz');
					return true;
				}).respond();
				scope.newAccount.unit = 'oz';
				scope.create();
				$httpBackend.flush();
			});
			
			describe('on success', function() {
				beforeEach(function() {
					$httpBackend.whenPOST('ledgers/ledger-332/accounts').respond();
				});
				
				it('should add the account', function() {
					scope.create();
					$httpBackend.flush();
					expect(accounts.add).toHaveBeenCalledWith({aggregate_id: 'account-223', name: 'New account', currency_code: 'UAH', currency: scope.newAccount.currency, balance: 233231, is_closed: false})
				});
			
				it('include unit', function() {
					scope.newAccount.unit = 'oz';
					scope.create();
					$httpBackend.flush();
					expect(accounts.add).toHaveBeenCalledWith(jasmine.objectContaining({unit: 'oz'}))
				});
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
				scope.newAccount.currency =  {code: 'UAH'};
				scope.newAccount.initialBalance = '2200.30';
				scope.newAccount.unit = 'oz';
				scope.createAnother();
				$httpBackend.flush();
				expect(scope.newAccount.name).toBeNull();
				expect(scope.newAccount.currency).toBeNull();
				expect(scope.newAccount.initialBalance).toEqual('0');
				expect(scope.newAccount.unit).toBeNull();
			});
		});
	});
});