(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .directive('pendingTransactionsMenuInjector', pendingTransactionsMenuInjector);

  pendingTransactionsMenuInjector.$inject = ['transactions'];

  function pendingTransactionsMenuInjector(transactions) {
    var updateActionState = function(scope, element) {
      scope.count = transactions.getPendingCount();
      if(scope.count > 0) element.show();
      else element.hide();
    };
    return {
      restrict: 'E',
      replace: true,
      templateUrl: 'app/transactions/pending/pending-transactions-menu.html',
      scope: {},
      link: function(scope, element, attrs) {
        angular.element('#main-navbar-right').prepend(element);
        scope.$root.$on('pending-transactions-changed', function() {
          updateActionState(scope, element);
        });
        updateActionState(scope, element);
      }
    }
  }
})();