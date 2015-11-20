(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .provider('transactions', transactionsProvider);

  function transactionsProvider() {
    this.$get = transactionsService;
    this.setPendingTransactionsCount = setPendingTransactionsCount;
    
    transactionsService.$inject = ['$http', 'accounts'];

    function transactionsService($http, accounts) {
      var service = {
        getPendingCount: getPendingCount,
        processReportedTransaction: processReportedTransaction,
        processApprovedTransaction: processApprovedTransaction,
        processRejectedPendingTransaction: processRejectedPendingTransaction,
        moveTo: moveTo,
        convertType: convertType
      };
      return service;

      //////////

      function getPendingCount() {
        return pendingTransactionsCount;
      }
      
      function processReportedTransaction(command) {
        var account = accounts.getById(command.account_id);
        if(command.type_id == Transaction.incomeId || command.type_id == Transaction.refundId) {
          account.balance += command.amount;
        } else if(command.type_id == Transaction.expenseId) {
          account.balance -= command.amount;
        }
        if(command.is_transfer) {
          var receivingAccount = accounts.getById(command.receiving_account_id);
          receivingAccount.balance += command.amount_received;
        }
        command.tag_ids = jQuery.map(command.tag_ids, function(tag_id) {
          return '{' + tag_id + '}';
        }).join(',');
      }
      
      function processApprovedTransaction(transaction) {
        this.processReportedTransaction(transaction);
        pendingTransactionsCount--;
      }
      
      function processRejectedPendingTransaction(transaction) {
        pendingTransactionsCount--;
      }
      
      function moveTo(transaction, targetAccount) {
        var sourceAccount = accounts.getById(transaction.account_id);
        return $http.post('transactions/' + transaction.transaction_id + '/move-to/' + targetAccount.aggregate_id).then(function() {
          if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
            sourceAccount.balance -= transaction.amount;
            targetAccount.balance += transaction.amount;
            if(transaction.is_transfer) transaction.receiving_account_id = targetAccount.aggregate_id;
          } else if(transaction.type_id == Transaction.expenseId) {
            sourceAccount.balance += transaction.amount;
            targetAccount.balance -= transaction.amount;
            if(transaction.is_transfer) transaction.sending_account_id = targetAccount.aggregate_id;
          }
          transaction.account_id = targetAccount.aggregate_id;
          transaction.has_been_moved = true;
        });
      }
      
      function convertType(transaction, typeId) {
        var account = accounts.getById(transaction.account_id);
        return $http.put('accounts/' + account.aggregate_id + '/transactions/' + transaction.transaction_id + '/convert-type/' + typeId).then(function() {
          if(typeId == Transaction.expenseId && (transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId)) {
            account.balance -= transaction.amount * 2;
          } else if(transaction.type_id == Transaction.expenseId) {
            account.balance += transaction.amount * 2;
          }
          transaction.type_id = typeId;
        });
      }
    }

    var pendingTransactionsCount = 0;
    
    function setPendingTransactionsCount(value) {
      pendingTransactionsCount = value;
    };
  }
})();