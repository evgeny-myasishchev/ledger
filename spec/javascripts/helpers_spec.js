describe("homeApp", function() {
	beforeEach(function() {
		module('ledgerHelpers');
	});
	
	describe('$pooledCompile.newPool', function() {
		var subject, rootScope;
		beforeEach(function() {
			inject(function($pooledCompile, $rootScope) {
				subject = $pooledCompile;
				rootScope = $rootScope;
			});
		});
		
		it('should create a new compilation pool that compiles templates', function(done) {
			var pool = subject.newPool('<input type="text" ng-model="textValue" />', {
				debug: true, 
				initScope: function(scope) { scope.textValue = 'New value'; },
				onResolved: function() { rootScope.$apply(); }
			});
			pool.compile().then(function(result) {
				expect(result.element.prop('tagName')).toEqual('INPUT');
				expect(result.element.attr('type')).toEqual('text');
				// expect(result.element.val()).toBeFalsy();
				// result.scope.textValue = 'New value';
				// result.scope.$wait();
				expect(result.element.val()).toEqual('New value');
				done();
			});
		});
	});
});