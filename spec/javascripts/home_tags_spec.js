describe("TagsController", function() {
	var tag1, tag2, tag3;
	var controller, scope, tags;
	beforeEach(function() {
		module('homeApp');
		homeApp.config(['tagsProvider', function(tagsProvider) {
			tagsProvider.assignTags([
				tag1 = {tag_id: 110, name: 'Tag 110'}, tag2 = {tag_id: 120, name: 'Tag 120'}, tag3 = {tag_id: 130, name: 'Tag 130'}
			]);
		}]);
		inject(['$httpBackend', '$rootScope', '$controller', 'tags', function(_$httpBackend_, $rootScope, $controller, t) {
			$httpBackend = _$httpBackend_;
			scope = $rootScope.$new();
			controller = $controller('TagsController', {$scope: scope});
			tags = t;
		}]);
	});
	
	it('should assign scope tags', function() {
		expect(scope.tags).toEqual([tag1, tag2, tag3]);
	});
	
	it('should delegate rename to tags service', function() {
		var promise = {};
		spyOn(tags, 'rename').and.returnValue(promise);
		expect(scope.renameTag(tag1, 'New name')).toBe(promise);
		expect(tags.rename).toHaveBeenCalledWith(tag1.tag_id, 'New name');
	});
	
	it('should delegate remove to tags service', function() {
		spyOn(tags, 'remove');
		scope.removeTag(tag1);
		expect(tags.remove).toHaveBeenCalledWith(tag1.tag_id);
	});
})