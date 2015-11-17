//= require_self
//= require_tree .

!function() {
  var profileApp = angular.module('profileApp', ['ErrorHandler', 'ngRoute']);

  profileApp.controller('ProfileController', ['$scope', function($scope) {

  }]);

  profileApp.config(['$routeProvider', function($routeProvider) {
      $routeProvider.when('/profile', {
        templateUrl: "profile.html",
        controller: 'ProfileController'
      });
    }
  ]);
}();