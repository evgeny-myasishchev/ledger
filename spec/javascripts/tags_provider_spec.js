describe("tagsProvider", function() {
	var tags, t1, t2, t3;
	var $httpBackend;
	beforeEach(function() {
		module('tagsProvider');
		angular.module('tagsProvider').config(['tagsProvider', function(tagsProvider) {
			tagsProvider.assignTags([
				t1 = {tag_id: 100, name: 'Tag 100'}, t2 = {tag_id: 110, name: 'Tag 110'}, t3 = {tag_id: 120, name: 'Tag 120'},
			]);
		}]);

		HomeHelpers.include(this);
		this.assignActiveLedger({aggregate_id: 'ledger-332'});

		inject(['$httpBackend', 'tags', function(hb, t) {
			$httpBackend = hb;
			tags = t;
		}]);
	});

	describe('tags provider', function() {
		it('should assign and get all tags', function() {
			expect(tags.getAll()).toEqual([t1, t2, t3]);
		});
	});

	describe('create', function() {
		it('should post the name onto create url and insert new tag', function() {
			$httpBackend.expectPOST('ledgers/ledger-332/tags', function(data) {
				var command = JSON.parse(data);
				expect(command.name).toEqual('New tag 223');
				return true;
			}).respond(200, JSON.stringify({tag_id: 223}));
			expect(tags.create('New tag 223').success).toBeDefined();
			$httpBackend.flush();
			expect(tags.getAll()).toContain({tag_id: 223, name: 'New tag 223'});
		});
	});

	describe('rename', function() {
		it('should put the name onto rename url and update name of the corresponding tag', function() {
			$httpBackend.expectPUT('ledgers/ledger-332/tags/100', function(data) {
				var command = JSON.parse(data);
				expect(command.name).toEqual('New tag 100');
				return true;
			}).respond(200);
			expect(tags.rename(100, 'New tag 100').success).toBeDefined();
			$httpBackend.flush();
			expect(t1.name).toEqual('New tag 100');
		});
	});

	describe('remove', function() {
		it('should delete onto destory url and remove corresponding tag from tags', function() {
			$httpBackend.expectDELETE('ledgers/ledger-332/tags/100').respond(200);
			expect(tags.remove(100).success).toBeDefined();
			$httpBackend.flush();
			expect(tags.getAll()).toEqual([t2, t3]);
		});
	});
});
