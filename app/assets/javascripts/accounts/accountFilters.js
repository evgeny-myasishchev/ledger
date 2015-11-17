!function() {
  'use strict';
  
  angular
    .module('accountsApp')
    .filter('activateFirstAccount', activateFirstAccount)
    .filter('calculateTotal', calculateTotal)
    .filter('nameWithBalance', nameWithBalance)
    .filter('categoryName', categoryName)
    .filter('accountById', accountById);

  activateFirstAccount.$inject = ['accounts', '$location']; 

  function activateFirstAccount(accounts, $location) {
    return function(account) {
      var activeAccount = accounts.getActive();
      if(activeAccount) return account;
      else if($location.$$path.indexOf('/accounts/') == 0) return account;
      accounts.makeActive(account);
      return account;
    }
  }

  calculateTotal.$inject = ['ledgers', 'accounts', 'money'];
  
  function calculateTotal(ledgers, accountsService, money) {
    return function(accounts, scope, resultExpression) {
      var that = this;
      ledgers.loadCurrencyRates().then(function(rates) {
        var result = 0;
        $.each(accounts, function(index, account) {
          var actualBalance = accountsService.getActualBalance(account, rates);
          if(actualBalance) result += actualBalance;
        });
        scope.$eval(resultExpression + '=' + result);
      });
      return accounts;
    }
  }

  nameWithBalance.$inject = ['moneyFilter'];
  
  function nameWithBalance(money) {
    return function(account) {
      return account.name + ' (' + money(account.balance) + ' ' + account.currency_code + ')';
    }
  }

  categoryName.$inject = ['accounts'];
  
  function categoryName(accounts) {
    return function(categoryId) {
      try {
        return accounts.getCategoryById(parseInt(categoryId)).name;
      } catch(e) {
        return null;
      }
    }
  }

  accountById.$inject = ['accounts'];
  
  function accountById(accounts) {
    return function(accountId) {
      return accounts.getById(accountId);
    }
  }
}();