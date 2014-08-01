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
	});
});