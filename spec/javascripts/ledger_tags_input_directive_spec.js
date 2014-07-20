describe('ledgerTagsInput', function() {
	var scope;
	beforeEach(function() {
		module('ledgerDirectives');
		ledgerDirectives.constant('tags', [
		{tag_id: 100, name: 'Tag 100'},
		{tag_id: 101, name: 'Tag 101'},
		{tag_id: 102, name: 'Tag 102'}
		]);
		inject(function($rootScope) {
			scope = $rootScope.$new();
		});
	});

	function compile(scope) {
		var result;
		inject(function($compile) {
			result = $compile('<ledger-tags ng-model="tag_ids" />')(scope);
		});
		scope.$digest();
		return result;
	};
  
	it('should set initial tags', function() {
		throw 'not implemented';
	});
  
	it('should update model when tags changed', function() {
		throw 'not implemented';
	});
});