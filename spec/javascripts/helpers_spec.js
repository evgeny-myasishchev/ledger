describe("ledgerHelpers", function() {
	var tags;
	beforeEach(function() {
		module('ledgerHelpers');
		tags = [{tag_id: 100, name: 'Tag 100'}, {tag_id: 200, name: 'Tag 200'}]
	});

	describe('tagsHelper', function() {
		var subject
		beforeEach(inject(function(tagsHelper) { subject = tagsHelper; }));

		it('should index by id', function() {
			expect(subject.indexById(tags)).toEqual({ 100: tags[0], 200: tags[1] });
		});

		it('should index by name', function() {
			expect(subject.indexByName(tags)).toEqual({ 'tag 100': tags[0], 'tag 200': tags[1] });
		});

		it('should extract braced string to array', function() {
			expect(subject.bracedStringToArray(null)).toEqual([]);
			expect(subject.bracedStringToArray('')).toEqual([]);
			expect(subject.bracedStringToArray('{100}')).toEqual([100]);
			expect(subject.bracedStringToArray('{100},{120},{140}')).toEqual([100,120,140]);
		});

		it('shold convert array to braced string', function() {
			expect(subject.arrayToBracedString([])).toEqual('')
			expect(subject.arrayToBracedString([100])).toEqual('{100}')
			expect(subject.arrayToBracedString([100, 200, 300])).toEqual('{100},{200},{300}')
		});
	});

	describe('thenFilter', function() {
		var scope, $q, $rootScope;
		beforeEach(inject(['$q', '$rootScope', 'thenFilter', function(theQ, theRootScope, thenFilter) {
			$q = theQ;
			$rootScope = theRootScope;
			scope = $rootScope.$new();
			scope.thenFilter = thenFilter;
		}]));

		it('should evaluate given expression when promise is resolved', function() {
			var deferred = $q.defer();
			scope.thenFilter(deferred.promise, 'test="value"');
			deferred.resolve();
			$rootScope.$apply();
			expect(scope.test).toEqual('value');
		});
	});

	describe('units', function() {
		var subject
		beforeEach(inject(function(units) { subject = units; }));

		describe('convert', function() {
			it('should convert from gram to ounces', function() {
				expect(subject.convert('g', 'ozt', 10000)).toEqual(Math.floor((100 / 31.1034768) * 100));
			});
		});
	});

	describe('search', function() {
		var subject;
		var t1, t2, t3;
		beforeEach(function() {
			module('tagsProvider');
			angular.module('tagsProvider').config(['tagsProvider', function(tagsProvider) {
				tagsProvider.assignTags([
					t1 = {tag_id: 100, name: 'Tag 100'}, t2 = {tag_id: 110, name: 'Tag 110'}, t3 = {tag_id: 120, name: 'Tag 120'},
				]);
			}]);

			inject(function(search) {subject = search;})
		});

		describe("parseExpression", function() {
			it('should recognize money string as an amount', function() {
				expect(subject.parseExpression('3321.32')).toEqual({amount: 332132});
			});

			it('should recognize comma separated tags as tags', function() {
				expect(subject.parseExpression('Tag 100')).toEqual({tag_ids: [100]});
				expect(subject.parseExpression('Tag 100,Tag 110')).toEqual({tag_ids: [100, 110]});
				expect(subject.parseExpression('Tag 100, Tag 110, Tag 120')).toEqual({tag_ids: [100, 110, 120]});
			});

			it('should recognize regular text as comment', function() {
				expect(subject.parseExpression('Buying milk')).toEqual({comment: 'Buying milk'});
			});
		});

	});
});