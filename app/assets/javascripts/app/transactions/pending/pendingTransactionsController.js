(function () {
  // TODO: Extract service. Convert to controllerAs

  'use strict';
  
  angular.module('transactionsApp')
    .controller('PendingTransactionsController', PendingTransactionsController);

  PendingTransactionsController.$inject = ['$scope', '$http', 'accounts', 'money', 'transactions'];

  function PendingTransactionsController($scope, $http, accounts, money, transactions) {
    var vm = this;

    vm.adjustAndApprove = adjustAndApprove;
    vm.reject = reject;
    vm.startReview = startReview;
    vm.stopReview = stopReview;
    vm.loadPendingTransactions = loadPendingTransactions;
    
    vm.accounts = accounts.getAllOpen();
    vm.approvedTransactions = [];
    vm.pendingTransaction = null;
    vm.transactions = [];
    
    ////////////
    
    function adjustAndApprove() {
      if(!vm.pendingTransaction.tag_ids) vm.pendingTransaction.tag_ids = [];
      if(vm.pendingTransaction.account == null) throw new Error('Account should be specified');
      
      var commandData = jQuery.extend({
        account_id: vm.pendingTransaction.account.aggregate_id
      }, vm.pendingTransaction);
      delete(commandData.account);
      
      var action = '/adjust-and-approve';
      if(commandData.type_id == Transaction.transferKey) {
        action += '-transfer';
        commandData.type_id = Transaction.expenseId;
        commandData.sending_account_id = commandData.account_id;
        commandData.receiving_account_id = vm.pendingTransaction.receivingAccount.aggregate_id;
        delete(commandData.receivingAccount);
        commandData.is_transfer = true;
      } else {
        commandData.type_id = parseInt(vm.pendingTransaction.type_id);
      }
      
      return $http.post('pending-transactions/' + vm.pendingTransaction.transaction_id + action, commandData)
        .success(function() {
          vm.pendingTransaction = null;
          commandData.amount = money.parse(commandData.amount);
          if(commandData.is_transfer) {
            commandData.amount_received = money.parse(commandData.amount_received);
          }
          vm.approvedTransactions.unshift(commandData);
          var pendingTransaction = removePendingTransaction(commandData.transaction_id);
          transactions.processApprovedTransaction(pendingTransaction, commandData);
          $scope.$emit('pending-transactions-changed');
        });
    };

    function reject() {
      return $http.delete('pending-transactions/' + vm.pendingTransaction.transaction_id)
        .success(function() {
          removePendingTransaction(vm.pendingTransaction.transaction_id);
          transactions.processRejectedPendingTransaction(vm.pendingTransaction);
          vm.pendingTransaction = null;
          $scope.$emit('pending-transactions-changed');
        });
    }
    
    function startReview(transaction) {
      var account = transaction.account_id == null ? null : accounts.getById(transaction.account_id);
      vm.pendingTransaction = {
        transaction_id: transaction.transaction_id,
        amount: transaction.amount,
        date: transaction.date,
        tag_ids: transaction.tag_ids,
        comment: transaction.comment,
        account: account,
        type_id: transaction.type_id
      };
    }
    
    function stopReview() {
      vm.pendingTransaction = null;
    }
    
    function removePendingTransaction(transaction_id) {
      var transaction = jQuery.grep(vm.transactions, function(t) {
        return t.transaction_id == transaction_id;
      })[0];
      if(!transaction)
        throw new Error("Transaction '" + transaction_id + "' not found.");
      var index = vm.transactions.indexOf(transaction);
      return vm.transactions.splice(index, 1)[0];
    }
    
    function loadPendingTransactions() {
      $http.get('pending-transactions.json').success(function(data) {
        var transactions = data;
        jQuery.each(transactions, function(i, t) {
          if(t.date) t.date = new Date(t.date);
        });
        vm.transactions = transactions;
        
        //For testing
        // vm.startReview(vm.transactions[0]);
      });
    }
  }
})();