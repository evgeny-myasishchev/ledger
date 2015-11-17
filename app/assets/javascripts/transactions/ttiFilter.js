(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .filter('tti', tti);

  tti.$inject = [];

  function tti() {
    return function(t) {
      if(t.is_transfer || t.type == Transaction.transferKey) return 'glyphicon glyphicon-transfer';
      if(t.type_id == 1 || t.type == Transaction.incomeKey) return 'glyphicon glyphicon-plus';
      if(t.type_id == 2 || t.type == Transaction.expenseKey) return 'glyphicon glyphicon-minus';
      if(t.type_id == 3 || t.type == Transaction.refundKey) return 'glyphicon glyphicon-share-alt';
      return null;
    }
  }
})();