!function() {
  angular.module('profileApp').directive('devicesTable', [function() {
    return {
      restrict: 'E',
      templateUrl: 'profile/devices_table.html',
      link: function(scope, element, attrs) {

      }
    }
  }]);
}();