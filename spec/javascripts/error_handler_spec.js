describe('ErrorHandler', function() {
	var $httpBackend, $http, $rootScope;
	beforeEach(function() {
		module('ErrorHandler');
		inject(['$httpBackend', '$http', '$rootScope', function(hb, hp, rs) {
			$httpBackend = hb;
			$http = hp;
			$rootScope = rs;
		}]);
	});


	describe('http errors handling', function() {
		it('should handle http server errors and broadcast them', function() {
			var respond = $httpBackend.expectGET('some-data').respond(function() {
				return [500, null, null, 'Internal server error'];
			});
			var hasEmitt = false;
			var scope = $rootScope.$new();
			scope.$on('http.unhandled-server-error', function(evt, data) {
				expect(data.status).toEqual(500);
				expect(data.statusText).toEqual('Internal server error');
				hasEmitt = true;
			});
			$http.get('some-data');
			$httpBackend.flush();
			$rootScope.$digest();
			expect(hasEmitt).toBeTruthy();
		});
	});
});