(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .directive('newTransactionDetails', newTransactionDetails);

  newTransactionDetails.$inject = [];

  function newTransactionDetails() {
    return {
      restrict: 'E',
      templateUrl: 'app/transactions/report/new-transaction-details.html',
      scope: {
        transaction: '='
      },
      link: function(scope, element, attrs) {
        scope.$watch('transaction.amount', function(newVal) {
          if(!newVal) return;
          if(newVal[0] == '-') scope.transaction.type_id = Transaction.expenseId;
          else if(newVal[0] == '+') scope.transaction.type_id = Transaction.incomeId;
        });
      }
    }
  }
})();