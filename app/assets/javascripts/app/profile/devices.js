!function() {
  angular.module('profileApp').directive('devicesTable', ['$http', function($http) {
    return {
      restrict: 'E',
      templateUrl: 'profile/devices_table.html',
      link: function(scope, element, attrs) {
        scope.resetSecretKey = function(device) {
          device.is_confirming_reset = false;
          device.has_been_reset = false;
          device.is_resetting = true;
          $http.put('api/devices/' + device.id + '/reset-secret-key').success(function() {
            device.has_been_reset = true;
          }).finally(function() {
            device.is_resetting = false;
          });
        };

        $http.get('api/devices.json').success(function(data) {
          scope.devices = data;
        });
      }
    }
  }]);
}();