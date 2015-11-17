(function () {
  // TODO: Extract service. Convert to controllerAs

  'use strict';
  
  angular.module('transactionsApp')
    .controller('PendingTransactionsController', PendingTransactionsController);

  PendingTransactionsController.$inject = ['$scope', '$http', 'accounts', 'money', 'transactions'];

  function PendingTransactionsController($scope, $http, accounts, money, transactions) {
    $scope.approvedTransactions = [];
    $http.get('pending-transactions.json').success(function(data) {
      var transactions = data;
      jQuery.each(transactions, function(i, t) {
        if(t.date) t.date = new Date(t.date);
      });
      $scope.transactions = transactions;
      $scope.accounts = accounts.getAllOpen();
    });
    
    $scope.adjustAndApprove = function() {
      if(!$scope.pendingTransaction.tag_ids) $scope.pendingTransaction.tag_ids = [];
      if($scope.pendingTransaction.account == null) throw new Error('Account should be specified');
      
      var commandData = jQuery.extend({
        account_id: $scope.pendingTransaction.account.aggregate_id
      }, $scope.pendingTransaction);
      delete(commandData.account);
      
      var action = '/adjust-and-approve';
      if(commandData.type_id == Transaction.transferKey) {
        action += '-transfer';
        commandData.type_id = Transaction.expenseId;
        commandData.sending_account_id = commandData.account_id;
        commandData.receiving_account_id = $scope.pendingTransaction.receivingAccount.aggregate_id;
        delete(commandData.receivingAccount);
        commandData.is_transfer = true;
      } else {
        commandData.type_id = parseInt($scope.pendingTransaction.type_id);
      }
      
      $http.post('pending-transactions/' + $scope.pendingTransaction.transaction_id + action, commandData)
        .success(function() {
          $scope.pendingTransaction = null;
          commandData.amount = money.parse(commandData.amount);
          if(commandData.is_transfer) {
            commandData.amount_received = money.parse(commandData.amount_received);
          }
          $scope.approvedTransactions.unshift(commandData);
          removePendingTransaction(commandData.transaction_id);
          transactions.processApprovedTransaction(commandData);
          $scope.$emit('pending-transactions-changed');
        });
    };

    $scope.reject = function() {
      $http.delete('pending-transactions/' + $scope.pendingTransaction.transaction_id)
        .success(function() {
          removePendingTransaction($scope.pendingTransaction.transaction_id);
          $scope.pendingTransaction = null;
          $scope.$emit('pending-transactions-changed');
        });
    }
    
    $scope.startReview = function(transaction) {
      var account = transaction.account_id == null ? null : accounts.getById(transaction.account_id);
      $scope.pendingTransaction = {
        transaction_id: transaction.transaction_id,
        amount: transaction.amount,
        date: transaction.date,
        tag_ids: transaction.tag_ids,
        comment: transaction.comment,
        account: account,
        type_id: transaction.type_id
      };
    };
    
    $scope.stopReview = function() {
      $scope.pendingTransaction = null;
    };
    
    var removePendingTransaction = function(transaction_id) {
      var transaction = jQuery.grep($scope.transactions, function(t) {
        return t.transaction_id == transaction_id;
      })[0];
      var index = $scope.transactions.indexOf(transaction);
      $scope.transactions.splice(index, 1);
    };
    
    // $scope.startReview(transactions[0]);
  }
})();