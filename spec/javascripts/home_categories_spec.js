describe("CategoriesController", function() {
	var category1, category2, category3;
	var controller, scope, accounts;
	beforeEach(function() {
		module('homeApp');
		homeApp.config(['accountsProvider', function(accountsProvider) {
			accountsProvider.assignCategories([
				category1 = {category_id: 110, name: 'Category 110', display_order: 1},
				category2 = {category_id: 120, name: 'Category 120', display_order: 2},
				category3 = {category_id: 130, name: 'Category 130', display_order: 3}
			]);
		}]);
		inject(['$httpBackend', '$rootScope', '$controller', 'accounts', function(_$httpBackend_, $rootScope, $controller, a) {
			$httpBackend = _$httpBackend_;
			scope = $rootScope.$new();
			controller = $controller('CategoriesController', {$scope: scope});
			accounts = a;
		}]);
		HomeHelpers.include(this);
		this.assignActiveLedger({aggregate_id: 'ledger-332'});
	});
	
	it('should assign scope categories', function() {
		expect(scope.categories).toEqual([category1, category2, category3]);
	});
	
	describe('createCategory', function() {
		beforeEach(function() {
			scope.isCreated = true;
			var promise = jQuery.Deferred().promise();
			spyOn(accounts, 'addCategory');
			scope.newCategoryName = 'New category 223';
			$httpBackend.whenPOST('ledgers/ledger-332/categories').respond(200, JSON.stringify({category_id: 223}));
		});
		
		it('should post create category', function() {
			$httpBackend.expectPOST('ledgers/ledger-332/categories', function(data) {
				var command = JSON.parse(data);
				expect(command.name).toEqual('New category 223');
				return true;
			}).respond(200, JSON.stringify({category_id: 223}));
			scope.createCategory();
			$httpBackend.flush();
		});
		
		it('should reset flags and add category to accounts service on created', function() {
			expect(scope.createCategory().then).toBeDefined();
			expect(scope.isCreated).toBeFalsy();
			$httpBackend.flush();
			expect(scope.isCreated).toBeTruthy();
			expect(accounts.addCategory).toHaveBeenCalledWith(223, 'New category 223');
		});
	});
	
	it('should put update and assign new name on success', function() {
		$httpBackend.expectPUT('ledgers/ledger-332/categories/110', function(data) {
			var command = JSON.parse(data);
			expect(command.name).toEqual('New category name 110');
			return true;
		}).respond(200);
		expect(scope.renameCategory(category1, 'New category name 110').then).toBeDefined();
		$httpBackend.flush();
		expect(category1.name).toEqual('New category name 110');
	});
	
	describe('removeCategory', function() {
		beforeEach(function() {
			$httpBackend.expectDELETE('ledgers/ledger-332/categories/' + category1.category_id).respond(200);
			scope.removeCategory(category1);
		});
		
		it('should remove the category from accounts service on success', function() {
			spyOn(accounts, 'removeCategory');
			$httpBackend.flush();
			expect(accounts.removeCategory).toHaveBeenCalledWith(category1);
		});
	});
})