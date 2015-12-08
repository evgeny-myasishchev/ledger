describe('transactions.transactionsService', function() {
  var subject;
  var account1, account2, account3;

  beforeEach(module('transactionsApp'));

  beforeEach(function() {
    angular.module('transactionsApp').config(['transactionsProvider', 'accountsProvider', function(transactionsProvider, accountsProvider) {
      transactionsProvider.setPendingTransactionsCount(32);
      accountsProvider.assignAccounts([
        account1 = {id: 1, aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, is_closed: false},
        account2 = {id: 2, aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, is_closed: false},
        account3 = {id: 3, aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200, is_closed: false}
      ]);
    }]);
  });

  beforeEach(inject(function(_transactions_){
    subject = _transactions_;
  }));

  describe('processReportedTransaction', function() {
    beforeEach(function() {
      account1.balance = 500;
    });

    function doProcess(amount, typeId, initializer) {
      var transaction = {
        account_id: account1.aggregate_id,
        type_id: typeId,
        amount: amount,
        tag_ids: []
      };
      if(initializer) initializer(transaction);
      subject.processReportedTransaction(transaction);
      return transaction;
    };

    it('should convert tags to braced string', function() {
      var transaction = doProcess(100, Transaction.incomeId, function(transaction) {
        transaction.tag_ids =[1, 2];
      });
      expect(transaction.tag_ids).toEqual('{1},{2}');
    });

    it('should update the balance on income', function() {
      doProcess(100, Transaction.incomeId);
      expect(account1.balance).toEqual(600);
    });

    it('should update the balance on expense', function() {
      doProcess(100, Transaction.expenseId);
      expect(account1.balance).toEqual(400);
    });

    it('should update the balance on refund', function() {
      doProcess(100, Transaction.refundId);
      expect(account1.balance).toEqual(600);
    });

    it('should update the balance on on transfer', function() {
      var receivingAccount = account2;
      receivingAccount.balance = 10000;
      doProcess(100, Transaction.expenseId, function(transaction) {
        transaction.is_transfer = true;
        transaction.receiving_account_id = receivingAccount.aggregate_id;
        transaction.amount_received = 5000;
      });
      expect(account1.balance).toEqual(400);
      expect(receivingAccount.balance).toEqual(15000);
    });
  });

  describe('processApprovedTransaction', function() {

    function doProcess(amountWas, typeIdWas, amount, typeId, initializer) {
      var pendingTransaction = {
        account_id: account1.aggregate_id,
        type_id: typeIdWas,
        amount: amountWas
      };
      var approvedTransaction = {
        account_id: account1.aggregate_id,
        type_id: typeId,
        amount: amount,
        tag_ids: []
      };
      if(initializer) initializer(pendingTransaction, approvedTransaction);
      subject.processApprovedTransaction(pendingTransaction, approvedTransaction);
      return approvedTransaction;
    };

    it('should processReportedTransaction', function() {
      spyOn(subject, 'processReportedTransaction');
      var transaction = doProcess(100, Transaction.incomeId, 100, Transaction.incomeId);
      expect(subject.processReportedTransaction).toHaveBeenCalledWith(transaction);
    });

    it('should process pendingTransaction with processRejectedPendingTransaction', function() {
      spyOn(subject, 'processRejectedPendingTransaction');
      var pendingTransaction;
      doProcess(100, Transaction.incomeId, 100, Transaction.incomeId, function(pt) {
        pendingTransaction = pt;
      });
      expect(subject.processRejectedPendingTransaction).toHaveBeenCalledWith(pendingTransaction);
    });

    it('should decrement pending transactions count', function() {
      doProcess(100, Transaction.incomeId, 100, Transaction.incomeId);
      expect(subject.getPendingCount()).toEqual(31);
    });
  });
  
  describe('processRejectedPendingTransaction', function() {
    it('should decrement count by one', function() {
      var pendingCount = subject.getPendingCount();
      subject.processRejectedPendingTransaction({id: 100});
      expect(subject.getPendingCount()).toEqual(pendingCount-1);
    });

    describe('with account', function() {
      var pendingTransaction;
      beforeEach(function() {
        account2.pending_balance = 150000;
        pendingTransaction = { account_id: account2.aggregate_id, amount: '500.25' };
      });

      it('should add amount to pending_balance for expense transactions', function() {
        pendingTransaction.type_id = Transaction.expenseId;
        subject.processRejectedPendingTransaction(pendingTransaction);
        expect(account2.pending_balance).toEqual(150000 + 50025)
      });

      it('should subtract amount from pending_balance for income transactions', function() {
        pendingTransaction.type_id = Transaction.incomeId;
        subject.processRejectedPendingTransaction(pendingTransaction);
        expect(account2.pending_balance).toEqual(150000 - 50025)
      });

      it('should subtract amount from pending_balance for refund transactions', function() {
        pendingTransaction.type_id = Transaction.refundId;
        subject.processRejectedPendingTransaction(pendingTransaction);
        expect(account2.pending_balance).toEqual(150000 - 50025)
      });
    });
  });

  describe('moveTo', function() {
    var transaction, sourceAccount, targetAccount;
    var $httpBackend;
    beforeEach(inject(function($injector) {
      sourceAccount = account1;
      targetAccount = account2;
      transaction = {
        transaction_id: 't-32',
        account_id: account1.aggregate_id,
        amount: 450,
        type_id: Transaction.incomeId
      };
      sourceAccount.balance = 5450;
      targetAccount.balance = 3450;
      $httpBackend = $injector.get('$httpBackend');
      $httpBackend.whenPOST('transactions/t-32/move-to/' + targetAccount.aggregate_id).respond(200);
    }));

    afterEach(function() {
      $httpBackend.verifyNoOutstandingExpectation();
      $httpBackend.verifyNoOutstandingRequest();
    });

    it('should post move action', function() {
      $httpBackend.expectPOST('transactions/t-32/move-to/' + targetAccount.aggregate_id).respond(200);
      var result = subject.moveTo(transaction, targetAccount);
      $httpBackend.flush();
      expect(result.then).toBeDefined();
    });

    it('should update account id and put has_been_moved flag of the transaction on success', function() {
      subject.moveTo(transaction, targetAccount);
      $httpBackend.flush();
      expect(transaction.account_id).toEqual(targetAccount.aggregate_id);
      expect(transaction.has_been_moved).toBeTruthy();
    });

    it('should update sending_account_id on success for expense transfer', function() {
      transaction.type_id = Transaction.expenseId;
      transaction.is_transfer = true;
      subject.moveTo(transaction, targetAccount);
      $httpBackend.flush();
      expect(transaction.sending_account_id).toEqual(targetAccount.aggregate_id);
    });

    it('should update receiving_account_id on success for income transfer', function() {
      transaction.type_id = Transaction.incomeId;
      transaction.is_transfer = true;
      subject.moveTo(transaction, targetAccount);
      $httpBackend.flush();
      expect(transaction.receiving_account_id).toEqual(targetAccount.aggregate_id);
    });

    it('should update balance of source and target accounts for income transaction on success', function() {
      subject.moveTo(transaction, targetAccount);
      $httpBackend.flush();
      expect(sourceAccount.balance).toEqual(5000);
      expect(targetAccount.balance).toEqual(3900);
    });

    it('should update balance of source and target accounts for expense transaction on success', function() {
      transaction.type_id = Transaction.expenseId;
      subject.moveTo(transaction, targetAccount);
      $httpBackend.flush();
      expect(sourceAccount.balance).toEqual(5900);
      expect(targetAccount.balance).toEqual(3000);
    });

    it('should update balance of source and target accounts for refund transaction on success', function() {
      transaction.type_id = Transaction.refundId;
      subject.moveTo(transaction, targetAccount);
      $httpBackend.flush();
      expect(sourceAccount.balance).toEqual(5000);
      expect(targetAccount.balance).toEqual(3900);
    });
  });

  describe('convertType', function() {
    var incomeTransaction, expenseTransaction;
    var $httpBackend;
    beforeEach(inject(function($injector) {
      incomeTransaction = {
        transaction_id: 't-32',
        account_id: account1.aggregate_id,
        amount: 450,
        type_id: Transaction.incomeId
      };
      expenseTransaction = {
        transaction_id: 't-33',
        account_id: account1.aggregate_id,
        amount: 450,
        type_id: Transaction.expenseId
      };
      account1.balance = 5450;
      $httpBackend = $injector.get('$httpBackend');
    }));

    afterEach(function() {
      $httpBackend.verifyNoOutstandingExpectation();
      $httpBackend.verifyNoOutstandingRequest();
    });

    it('should put convert action and update type_id on success', function() {
      $httpBackend
      .expectPUT('accounts/' + account1.aggregate_id + '/transactions/' + incomeTransaction.transaction_id + '/convert-type/' + Transaction.expenseId)
      .respond(200);
      var result = subject.convertType(incomeTransaction, Transaction.expenseId);
      $httpBackend.flush();
      expect(result.then).toBeDefined();
      expect(incomeTransaction.type_id).toEqual(Transaction.expenseId);
    });

    it('should update the balance when converting income to expense', function() {
      $httpBackend
      .whenPUT('accounts/' + account1.aggregate_id + '/transactions/' + incomeTransaction.transaction_id + '/convert-type/' + Transaction.expenseId)
      .respond(200);
      subject.convertType(incomeTransaction, Transaction.expenseId);
      $httpBackend.flush();
      expect(account1.balance).toEqual(4550);
    });

    it('should update the balance when converting refund to expense', function() {
      incomeTransaction.type_id = Transaction.refundId;
      $httpBackend
      .whenPUT('accounts/' + account1.aggregate_id + '/transactions/' + incomeTransaction.transaction_id + '/convert-type/' + Transaction.expenseId)
      .respond(200);
      subject.convertType(incomeTransaction, Transaction.expenseId);
      $httpBackend.flush();
      expect(account1.balance).toEqual(4550);
    });

    it('should not change the balance if converting income to refund', function() {
      $httpBackend
      .whenPUT('accounts/' + account1.aggregate_id + '/transactions/' + incomeTransaction.transaction_id + '/convert-type/' + Transaction.refundId)
      .respond(200);
      subject.convertType(incomeTransaction, Transaction.refundId);
      $httpBackend.flush();
      expect(account1.balance).toEqual(5450);
    });

    it('should not change the balance if converting refund to income', function() {
      incomeTransaction.type_id = Transaction.refundId;
      $httpBackend
      .whenPUT('accounts/' + account1.aggregate_id + '/transactions/' + incomeTransaction.transaction_id + '/convert-type/' + Transaction.incomeId)
      .respond(200);
      subject.convertType(incomeTransaction, Transaction.incomeId);
      $httpBackend.flush();
      expect(account1.balance).toEqual(5450);
    });

    it('should update the balance when converting expense to income', function() {
      $httpBackend
      .whenPUT('accounts/' + account1.aggregate_id + '/transactions/' + expenseTransaction.transaction_id + '/convert-type/' + Transaction.incomeId)
      .respond(200);
      subject.convertType(expenseTransaction, Transaction.incomeId);
      $httpBackend.flush();
      expect(account1.balance).toEqual(6350);
    });

    it('should update the balance when converting expense to refund', function() {
      $httpBackend
      .whenPUT('accounts/' + account1.aggregate_id + '/transactions/' + expenseTransaction.transaction_id + '/convert-type/' + Transaction.refundId)
      .respond(200);
      subject.convertType(expenseTransaction, Transaction.refundId);
      $httpBackend.flush();
      expect(account1.balance).toEqual(6350);
    });
  });
});