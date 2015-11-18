(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .directive('reviewAndApprovePending', reviewAndApprovePending);

  reviewAndApprovePending.$inject = [];

  function reviewAndApprovePending() {
    return {
      restrict: 'E',
      replace: true,
      templateUrl: 'app/transactions/pending/review-and-approve-pending-transaction.html',
      link: function(scope, element, attrs) {
        element.modal({
          show: false
        });

        element.on('shown.bs.modal', function() {
          element.find('select:first').focus();
        });

        scope.$watch('vm.pendingTransaction', function(newVal) {
          if(newVal) {
            scope.confirmingRejection = false;
            element.modal('show');
          } else {
            element.modal('hide');
          }
        });
      }
    }
  }
})();