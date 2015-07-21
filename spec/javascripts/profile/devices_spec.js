describe('profile.devices', function() {
	describe('devicesTable directive', function() {
		var $httpBackend, scope, dev1, dev2, dev3;
		beforeEach(function() {
			module('profileApp');
			dev1 = {id: 1, device_id: 'dev-1', name: 'Dev 1'};
			dev2 = {id: 2, device_id: 'dev-2', name: 'Dev 2'};
			dev3 = {id: 3, device_id: 'dev-3', name: 'Dev 3'};
			inject(function($rootScope, _$httpBackend_) {
				scope = $rootScope.$new();
				$httpBackend = _$httpBackend_;
			})
		});
		
		function compile() {
			var result;
			inject(function($compile) {
				result = $compile('<script type="text/ng-template" id="profile/devices_table.html"></script><devices-table></devices-table>')(scope);
			});
			scope.$digest();
			return result;
		};
		
		it('should load the devices', function() {
			$httpBackend.expectGET('api/devices.json').respond([dev1, dev2, dev3]);
			compile();
			$httpBackend.flush();
			console.log('flushed');
			console.log(scope);
			expect(scope.devices).toEqual([dev1, dev2, dev3]);
		});
	});
});