!function() {
  'use strict';
  
  angular
    .module('homeApp')
    .config(config);

  config.$inject = ['$routeProvider'];

  function config($routeProvider) {
    $routeProvider
      .when('/tags', {
        templateUrl: "tags.html",
        controller: 'TagsController'
      })
      .when('/categories', {
        templateUrl: "categories.html",
        controller: 'CategoriesController'
      })
      .when('/accounts', {
        templateUrl: "accounts.html",
        controller: 'HomeController'
      }).when('/accounts/new', {
        templateUrl: "new_account.html",
        controller: 'NewAccountController'
      })
      .when('/accounts/:accountSequentialNumber', {
        templateUrl: "accounts.html",
        controller: 'HomeController'
      }).otherwise({
        redirectTo: '/accounts'
      });
  }
}();