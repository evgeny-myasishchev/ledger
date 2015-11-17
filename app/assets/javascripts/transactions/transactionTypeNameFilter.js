(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .filter('transactionTypeName', transactionTypeName);

  function transactionTypeName(){
    return function(typeId) {
      return Transaction.TypeById[typeId].t();
    }
  }
})();