(function () {
  'use strict';
  
  angular.module('accountsApp')
    .directive('selectAccount', selectAccount);

  selectAccount.$inject = ['accounts'];

  function selectAccount(accounts) {
    return {
      restrict: 'E',
      replace: true,
      template: 
          "<select ng-options='account | nameWithBalance group by (account.category_id | categoryName) for account in accounts | filter:filterAccount | orderBy:\"name\"' " + 
            "class='form-control' required>" + 
          "</select>",
      scope: {
        account: '=ngModel',
        except: '='
      },
      link: function(scope, element, attrs) {
        scope.accounts = accounts.getAll();
        var exceptMap = {};
        if(scope.except) {
          if($.isArray(scope.except)) {
            $.each(scope.except, function(i, account) {
              exceptMap[account.aggregate_id] = true;
            })
          } else {
            exceptMap[scope.except.aggregate_id] = true;
          }
        }
        scope.filterAccount = function(account) {
          return !exceptMap[account.aggregate_id] && !account.is_closed;
        }
      }
    }
  }
})();