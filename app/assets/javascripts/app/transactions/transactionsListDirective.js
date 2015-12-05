(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .directive('transactionsList', transactionsList);

  transactionsList.$inject = ['$http', 'accounts', 'tagsHelper', 'money'];

  function transactionsList($http, accounts, tagsHelper, money) {
    return {
      restrict: 'E',
      templateUrl: 'app/transactions/transactions-list.html',
      scope: {
        showAccount: '=',
        transactions: '=data'
      },
      link: function(scope, element, attrs) {
        if(typeof(attrs.data) == 'undefined') {
          throw 'Failed to initialize transactions list: data attribute is required.';
        }
        scope.adjustComment = function(transaction, comment) {
          return $http.post('transactions/' + transaction.transaction_id + '/adjust-comment', {
            comment: comment
          }).success(function() {
            transaction.comment = comment;
          });
        };
        
        scope.adjustTags = function(transaction, tag_ids) {
          return $http.post('transactions/' + transaction.transaction_id + '/adjust-tags', {
            tag_ids: tag_ids
          }).success(function() {
            transaction.tag_ids = tagsHelper.arrayToBracedString(tag_ids);
          });
        };
    
        scope.adjustDate = function(transaction, date) {
          return $http.post('transactions/' + transaction.transaction_id + '/adjust-date', {
            date: date.toJSON()
          }).success(function() {
            transaction.date = date;
          });
        };
        
        scope.adjustAmount = function(transaction, amount) {
          amount = money.parse(amount);
          return $http.post('transactions/'+ transaction.transaction_id + '/adjust-amount', {
            amount: amount
          }).success(function() {
            var oldAmount = transaction.amount;
            transaction.amount = amount;
            var account = accounts.getById(transaction.account_id);
            if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
              account.balance = account.balance - oldAmount + amount;
            } else if (transaction.type_id == Transaction.expenseId) {
              account.balance = account.balance + oldAmount- amount;
            }
          });
        };
        
        scope.removeTransaction = function(transaction) {
          return $http.delete('transactions/' + transaction.transaction_id).success(function() {
            scope.transactions.splice(scope.transactions.indexOf(transaction), 1);
            var account = accounts.getById(transaction.account_id);
            if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
              account.balance -= transaction.amount;
            } else if (transaction.type_id == Transaction.expenseId) {
              account.balance += transaction.amount;
            }
          });
        };
        
        scope.getTransferAmountSign = function(transaction) {
          if(transaction.is_transfer) {
            return transaction.type_id == 2 ? '-' : '+';
          } else {
            return null;
          }
        };
      }
    }
  }
})();