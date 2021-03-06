(function() {
  'use strict';

  angular
    .module('transactionsApp')
    .directive('transactionsList', transactionsList);

  transactionsList.$inject = ['$http', 'accounts', 'tagsHelper', 'money'];

  function transactionsList($http, accounts, tagsHelper, money) {
    TransactionsListController.$inject = ['$scope'];

    return {
      restrict: 'E',
      templateUrl: 'app/transactions/transactions-list.html',
      controller: TransactionsListController,
      controllerAs: 'vm',
      scope: {
        showAccount: '=',
        transactions: '=data'
      },
      link: linkFn
    };

    ///////////////////////////

    function TransactionsListController($scope) {
      var vm = this;

      vm.adjustComment = function(transaction, comment) {
        return $http.post('transactions/' + transaction.transaction_id + '/adjust-comment', {
          comment: comment
        }).success(function() {
          transaction.comment = comment;
        });
      };

      vm.adjustTags = function(transaction, tag_ids) {
        return $http.post('transactions/' + transaction.transaction_id + '/adjust-tags', {
          tag_ids: tag_ids
        }).success(function() {
          transaction.tag_ids = tagsHelper.arrayToBracedString(tag_ids);
        });
      };

      vm.adjustDate = function(transaction, date) {
        return $http.post('transactions/' + transaction.transaction_id + '/adjust-date', {
          date: date.toJSON()
        }).success(function() {
          transaction.date = date;
        });
      };

      vm.adjustAmount = function(transaction, amount) {
        amount = money.parse(amount);
        return $http.post('transactions/' + transaction.transaction_id + '/adjust-amount', {
          amount: amount
        }).success(function() {
          var oldAmount = transaction.amount;
          transaction.amount = amount;
          var account = accounts.getById(transaction.account_id);
          if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
            account.balance = account.balance - oldAmount + amount;
          } else if(transaction.type_id == Transaction.expenseId) {
            account.balance = account.balance + oldAmount - amount;
          }
        });
      };

      vm.removeTransaction = function(transaction) {
        return $http.delete('transactions/' + transaction.transaction_id).success(function() {
          $scope.transactions.splice($scope.transactions.indexOf(transaction), 1);
          var account = accounts.getById(transaction.account_id);
          if(transaction.type_id == Transaction.incomeId || transaction.type_id == Transaction.refundId) {
            account.balance -= transaction.amount;
          } else if(transaction.type_id == Transaction.expenseId) {
            account.balance += transaction.amount;
          }
        });
      };

      vm.getTransferAmountSign = function(transaction) {
        if(transaction.is_transfer) {
          return transaction.type_id == 2 ? '-' : '+';
        } else {
          return null;
        }
      };
    }

    function linkFn(scope, element, attrs, vm) {
      if(typeof(attrs.data) == 'undefined') {
        throw 'Failed to initialize transactions list: data attribute is required.';
      }
      element.on('mouseenter', '[data-toggle=tooltip]', function(evt) {
        var element = jQuery(evt.target);
        element.tooltip('show');
        element.on('hidden.bs.tooltip', function(e) {
          element.tooltip('destroy');
        });
        scope.$on('$destroy', function() {
          element.tooltip('destroy');
        });
      });
    };
  }
})();