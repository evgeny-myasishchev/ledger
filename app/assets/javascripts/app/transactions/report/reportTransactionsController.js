!function() {
  'use strict';
  
  angular
    .module('transactionsApp')
    .controller('ReportTransactionsController', ReportTransactionsController);

  ReportTransactionsController.$inject = ['$http', 'accounts', 'money', 'newUUID', 'transactions'];

  function ReportTransactionsController($http, accounts, money, newUUID, transactions) {
    var vm = this;

    //Actions
    vm.report = report;

    vm.accounts = accounts.getAllOpen();
    vm.reportedTransactions = [];
    vm.newTransaction = null;

    ////////////

    //For testing purposes
    // vm.reportedTransactions = [
    //  {"type":"income","amount":90,"tag_ids":'{1},{2}',"comment":"test123123","date":new Date("2014-07-16T21:09:27.000Z")},
    //  {"type":"expense","amount":2010,"tag_ids":'{2}',"comment":null,"date":new Date("2014-07-16T21:09:06.000Z")},
    //  {"type":"expense","amount":1050,"tag_ids":'{2},{3}',"comment":"Having lunch and getting some food","date":new Date("2014-07-16T21:08:51.000Z")},
    //  {"type":"refund","amount":1050,"tag_ids":'{2},{3}',"comment":"Having lunch and getting some food","date":new Date("2014-07-16T21:08:51.000Z")},
    //  {"type":"expense","amount":1050,"tag_ids":null,"comment":"test1","date":new Date("2014-07-16T21:08:44.000Z")},
    //  {"type":"transfer","amount":1050,"tag_ids":null,"comment":null,"date":new Date("2014-06-30T21:00:00.000Z")}
    // ];
    
    function report() {
      var command = {
        transaction_id: newUUID(),
        amount: Math.abs(money.parse(vm.newTransaction.amount)),
        date: vm.newTransaction.date,
        tag_ids: vm.newTransaction.tag_ids,
        comment: vm.newTransaction.comment,
        type_id: vm.newTransaction.type_id,
        account_id: vm.newTransaction.account.aggregate_id
      };
      var typeKey;
      if(vm.newTransaction.type_id == Transaction.transferKey) {
        typeKey = Transaction.transferKey;
        command.type_id = Transaction.expenseId;
        command.sending_account_id = command.account_id;
        command.sending_transaction_id = command.transaction_id;
        command.receiving_transaction_id = newUUID();
        command.receiving_account_id = vm.newTransaction.receivingAccount.aggregate_id;
        command.amount_sent = command.amount;
        command.amount_received = Math.abs(money.parse(vm.newTransaction.amount_received));
        command.is_transfer = true;
      } else {
        typeKey = Transaction.TypeKeyById[vm.newTransaction.type_id];
        command.is_transfer = false;
      }
      return $http.post('accounts/' + vm.newTransaction.account.aggregate_id + '/transactions/report-' + typeKey, command).success(function() {
        resetNewTransaction();
        processReportedTransaction(command);
      });
    };

    var processReportedTransaction = function(command) {
      transactions.processReportedTransaction(command);
      vm.reportedTransactions.unshift(command);
    };
  
    var resetNewTransaction = function() {
      vm.newTransaction = {
        account: accounts.getActive(),
        amount: null,
        tag_ids: [],
        type_id: Transaction.expenseId,
        date: new Date(),
        comment: null
      };
      //For testing purposes
      // vm.newTransaction = {
      //   account: vm.accounts[0],
      //   amount: '332.03',
      //   tag_ids: [1, 2],
      //   type_id: Transaction.expenseId,
      //   date: new Date(),
      //   comment: 'Hello world, this is test transaction'
      // };
    };
    resetNewTransaction();
  }
}();