describe('ledgerTagsInput', function() {
	var scope;
	beforeEach(function() {
		module('ledgerDirectives');
		HomeHelpers.include(this);
		this.assignTags([
			{tag_id: 100, name: 'Tag 100'},
			{tag_id: 101, name: 'Tag 101'},
			{tag_id: 102, name: 'Tag 102'}
		]);
		inject(function($rootScope) {
			scope = $rootScope.$new();
		});
		scope.tag_ids = [100, 102];
	});

	function compile(scope) {
		var result;
		inject(function($compile) {
			result = $compile('<ledger-tags-input ng-model="tag_ids" />')(scope);
		});
		scope.$digest();
		return result;
	};

	it('should set initial tags', function() {
		var result = compile(scope);
		var input = result.find('input:first');
		var items = input.tagsinput('items');
		expect(items).toEqual(['Tag 100', 'Tag 102']);
	});

	it('should update model when tags changed', function() {
		var result = compile(scope);
		var input = result.find('input:first');
		scope.tag_ids = [101];
		scope.$digest();
		var items = input.tagsinput('items');
		expect(items).toEqual(['Tag 101']);
	});

	it('should update model when tags changed', function() {
		scope.tag_ids = [];
		var input = compile(scope).find('input:first');
		input.tagsinput('input').val('Tag 101');
		var e = jQuery.Event("keypress");
		e.keyCode = 13;
		input.tagsinput('input').trigger(e);
		var items = input.tagsinput('items');
		expect(items).toEqual(['Tag 101']);
	});
});