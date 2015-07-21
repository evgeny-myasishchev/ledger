!function() {
	angular.module('profileApp').directive('devicesTable', ['$http', function($http) {
		return {
			restrict: 'E',
			templateUrl: 'profile/devices_table.html',
			link: function(scope, element, attrs) {
				$http.get('api/devices.json').success(function(data) {
					scope.devices = data;
				});
			}
		}
	}]);
}();