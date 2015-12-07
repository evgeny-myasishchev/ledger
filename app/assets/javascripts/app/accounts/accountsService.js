!function() {
  'use strict';
  
  angular
    .module('accountsApp')
    .provider('accounts', accountsProvider);

  function accountsProvider() {
    this.$get = accountsService;
    this.assignAccounts = assignAccounts;
    this.assignCategories = assignCategories;

    accountsService.$inject = ['$routeParams', '$location', '$rootScope', 'ledgers', 'money', 'units'];

    function accountsService($routeParams, $location, $rootScope, ledgers, money, units) {
      return {
        getAll: function() {
          return accounts;
        },
        getAllOpen: function() {
          return $.grep(accounts || [], function(account) { 
            return !account.is_closed;
          });
        },
        getAllCategories: function() {
          return categories;
        },
        getCategoryById: function(categoryId) {
          var result = $.grep(categories, function(category) {
            return category.category_id == categoryId;
          });
          if(result.length == 0) throw 'Unknown category id=' + categoryId + '.';
          return result[0];
        },
        getActive: function() {
          var activeAccount = null;
          if($routeParams.accountSequentialNumber) {
            activeAccount = getActiveAccountFromRoute($routeParams.accountSequentialNumber);
          }
          return activeAccount;
        },
        getById: function(accountId) {
          var result = $.grep(accounts, function(account) { 
            return account.aggregate_id == accountId;
          });
          if(result.length == 0) throw 'Unknown account id=' + accountId;
          if(result.length > 1) throw 'Several accounts with the same id=' + accountId + ' found. This should never happen.';
          return result[0];
        },
        makeActive: function(account) {
          $location.path('/accounts/' + account.sequential_number);
        },
        add: function(account) {
          var lastSequentialNumber = 0;
          $.each(accounts, function(index, account) {
            if(account.sequential_number > lastSequentialNumber) lastSequentialNumber = account.sequential_number;
          });
          account.sequential_number = lastSequentialNumber + 1;
          account.category_id = null;
          accounts.push(account);
          $rootScope.$broadcast('account-added', account);
          return account;
        },
        remove: function(account) {
          var index = accounts.indexOf(account);
          accounts.splice(index, 1);
        },
        addCategory: function(category_id, name) {
          var lastDisplayOrder = 0;
          $.each(categories, function(index, category) {
            if(category.display_order > lastDisplayOrder) lastDisplayOrder = category.display_order;
          });
          categories.push({category_id: category_id, display_order: lastDisplayOrder + 1, name: name});
        },
        removeCategory: function(category) {
          var index = categories.indexOf(category);
          categories.splice(index, 1);
        },
        getActualBalance: function(account, rates) {
          var activeLedger = ledgers.getActiveLedger();
          var balance = account.balance + account.pending_balance;
          if(account.unit != account.currency.unit) {
            balance = units.convert(account.unit, account.currency.unit, balance);
          }
          if(activeLedger.currency_code == account.currency_code) {
            return balance;
          } else {
            var rate = rates[account.currency_code];
            if(rate) {
              return money.toIntegerMoney((money.toNumber(balance) * rate.rate));
            }
          }
        }
      }
    }

    var accounts, categories;
    function assignAccounts(value) {
      accounts = value;
    };
    function assignCategories(value) {
      categories = value;
    };
    var getActiveAccountFromRoute = function(sequential_number) {
      return jQuery.grep(accounts, function(a) { return a.sequential_number == sequential_number; })[0];
    };
  }
  
}();