describe('transactions.PendingTransactionsController', function() {
  var scope, $httpBackend, transactions, subject;
  var account1, account2, account3;
	
  beforeEach(function() {
    module('transactionsApp');
    angular.module('transactionsApp').config(['accountsProvider', function(accountsProvider) {
      accountsProvider.assignAccounts([
        account1 = {id: 1, aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, is_closed: false},
        account2 = {id: 2, aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, is_closed: false},
        account3 = {id: 3, aggregate_id: 'a-3', sequential_number: 203, 'name': 'VAB Visa', 'balance': 443200, is_closed: false}
      ]);
    }]);
    inject(function(_$httpBackend_, $rootScope, _transactions_){
      $httpBackend = _$httpBackend_;
      transactions = _transactions_;
      $httpBackend.whenGET('pending-transactions.json').respond([]);
    });
  });
	
  function initController() {
    inject(function($rootScope, $controller) {
      scope = $rootScope.$new();
      subject = $controller('PendingTransactionsController', {$scope: scope});
    });
  };
	
  it('should fetch pending transactions', function() {
    $httpBackend.expectGET('pending-transactions.json').respond(
      [{t1: true}, {t2: true}, {t3: true}]
    );
    initController();
    $httpBackend.flush();
    expect(subject.transactions).toEqual([{t1: true}, {t2: true}, {t3: true}]);
  });
	
  it("should have dates converted to date object", function() {
    date = new Date();
    $httpBackend.expectGET('pending-transactions.json').respond(
      [{t1: true, date: date.toJSON()}, {t2: true, date: date.toJSON()}, {t3: true, date: date.toJSON()}]
    );
    initController();
    $httpBackend.flush();
    jQuery.each(subject.transactions, function(i, t) {
      expect(t.date).toEqual(date);
    });
  });
	
  it("should assign open accounts", function() {
    $httpBackend.expectGET('pending-transactions.json').respond([]);
    account3.is_closed = true;
    initController();
    $httpBackend.flush();
    expect(subject.accounts).toEqual([account1, account2]);
  });
	
  describe('startReview', function() {
    beforeEach(function() {
      initController();
    });
		
    it('should initialize pending transaction', function() {
      var transaction;
      subject.startReview(transaction = {
        transaction_id: 't-332',
        amount: '223.43',
        date: new Date(),
        comment: 'Comment 332',
        account_id: account1.aggregate_id,
        type_id: 2
      });
			
      expect(subject.pendingTransaction.transaction_id).toEqual(transaction.transaction_id);
      expect(subject.pendingTransaction.amount).toEqual(transaction.amount);
      expect(subject.pendingTransaction.date).toEqual(transaction.date);
      expect(subject.pendingTransaction.tag_ids).toEqual(transaction.tag_ids);
      expect(subject.pendingTransaction.comment).toEqual(transaction.comment);
      expect(subject.pendingTransaction.account).toEqual(account1);
      expect(subject.pendingTransaction.type_id).toEqual(transaction.type_id);
    });
		
    it('should leave the account null if pending transaction has no account assigned', function() {
      subject.startReview(transaction = {
        transaction_id: 't-332',
        amount: '223.43',
        date: new Date(),
        comment: 'Comment 332',
        account_id: null,
        type_id: 2
      });
      expect(subject.pendingTransaction.account).toBeNull();
    });
  });
	
  describe('adjustAndApprove', function() {
    var pendingTransaction;
    beforeEach(function() {
      initController();
      subject.pendingTransaction = pendingTransaction = {
        transaction_id: 't-332',
        amount: '223.43',
        date: new Date(),
        comment: 'Comment 332',
        account: account1,
        type_id: 2
      };
    });
		
    it("should submit the adjust-and-approve", function() {
      $httpBackend.expectPOST('pending-transactions/t-332/adjust-and-approve', function(data) {
        var expectedCommand = jQuery.extend({
          account_id: subject.pendingTransaction.account.aggregate_id
        }, subject.pendingTransaction);
        delete(expectedCommand.account);

        var command = JSON.parse(data);
        command.date = new Date(command.date);
        expect(command).toEqual(expectedCommand);
        return true;
      }).respond();
      subject.adjustAndApprove();
      $httpBackend.flush();
    });
		
    it("should submit the adjust-and-approve-transfer", function() {
      subject.pendingTransaction.receivingAccount = account2;
      subject.pendingTransaction.amount_received = '4432.03';
      subject.pendingTransaction.type_id = Transaction.transferKey;
      $httpBackend.expectPOST('pending-transactions/t-332/adjust-and-approve-transfer', function(data) {
        var expectedCommand = jQuery.extend({
          account_id: subject.pendingTransaction.account.aggregate_id,
          sending_account_id: subject.pendingTransaction.account.aggregate_id,
          receiving_account_id: subject.pendingTransaction.receivingAccount.aggregate_id,
          is_transfer: true
        }, subject.pendingTransaction);
        expectedCommand.type_id = Transaction.expenseId;
        delete(expectedCommand.account);
        delete(expectedCommand.receivingAccount);

        var command = JSON.parse(data);
        command.date = new Date(command.date);
        expect(command).toEqual(expectedCommand);
        return true;
      }).respond();
      subject.adjustAndApprove();
      $httpBackend.flush();
    });
		
    it("convert null tags to empty array", function() {
      $httpBackend.expectPOST('pending-transactions/t-332/adjust-and-approve', function(data) {
        var command = JSON.parse(data);
        expect(command.tag_ids).toEqual([]);
        return true;
      }).respond();
      subject.pendingTransaction.tag_ids = null;
      subject.adjustAndApprove();
      $httpBackend.flush();
    });
		
    it("convert type_id to integer", function() {
      $httpBackend.expectPOST('pending-transactions/t-332/adjust-and-approve', function(data) {
        var command = JSON.parse(data);
        expect(command.type_id).toEqual(1);
        return true;
      }).respond();
      subject.pendingTransaction.type_id = "1";
      subject.adjustAndApprove();
      $httpBackend.flush();
    });
		
    describe('on success', function() {
      var changeEventEmitted, approvedTransaction;
      beforeEach(function() {
        $httpBackend.flush();
        $httpBackend.whenPOST('pending-transactions/t-332/adjust-and-approve').respond();
        subject.approvedTransactions = [{t1: true}, {t2: true}];
        subject.transactions  = [{t1: true}, jQuery.extend({}, pendingTransaction), {t2: true}];
        scope.$on('pending-transactions-changed', function() {
          changeEventEmitted = true;
        });
        spyOn(transactions, 'processApprovedTransaction');
        subject.adjustAndApprove();
        $httpBackend.flush();
				
        approvedTransaction = jQuery.extend({
          account_id: pendingTransaction.account.aggregate_id
        }, pendingTransaction);
        approvedTransaction.amount = 22343;
        delete(approvedTransaction.account);
      });
			
      it('should insert the transaction into the beginning of approvedTransactions', function() {
        expect(subject.approvedTransactions.length).toEqual(3);
        expect(subject.approvedTransactions[0]).toEqual(approvedTransaction);
      });
			
      it('should convert amount to integer', function() {
        expect(subject.approvedTransactions[0].amount).toEqual(22343);
      });
			
      it('should clear the pending transaction', function() {
        expect(subject.pendingTransaction).toBeNull();
      });
			
      it('should remove the transaction from pendingTransactions', function() {
        expect(subject.transactions.length).toEqual(2);
        expect(subject.transactions).toEqual([{t1: true}, {t2: true}]);
      });
			
      it('should emit pending-transactions-changed event', function() {
        expect(changeEventEmitted).toBeTruthy();
      });
			
      it('should use transactions provider to process approved transaction', function() {
        expect(transactions.processApprovedTransaction).toHaveBeenCalledWith(approvedTransaction);
      });
    });
		
    describe('on success transfer', function() {
      beforeEach(function() {
        pendingTransaction.type_id = Transaction.transferKey;
        pendingTransaction.receivingAccount = account2;
        pendingTransaction.amount_received = '1009.32'
        $httpBackend.flush();
        $httpBackend.whenPOST('pending-transactions/t-332/adjust-and-approve-transfer').respond();
        subject.approvedTransactions = [{t1: true}, {t2: true}];
        subject.transactions  = [{t1: true}, jQuery.extend({}, pendingTransaction), {t2: true}];
        subject.adjustAndApprove();
        $httpBackend.flush();
      });
			
      it('should convert amount_received to integer', function() {
        expect(subject.approvedTransactions[0].amount_received).toEqual(100932);
      });
    });
  });

  describe('reject', function() {
    var pendingTransaction;
    beforeEach(function() {
      initController();
      subject.pendingTransaction = pendingTransaction = {
        transaction_id: 't-332',
        amount: '223.43',
        date: new Date(),
        comment: 'Comment 332',
        account: account1,
        type_id: 2
      };
    });
		
    it("should send delete request", function() {
      $httpBackend.expectDELETE('pending-transactions/t-332').respond();
      subject.reject();
      $httpBackend.flush();
      expect(subject.pendingTransaction).toBeNull();
    });
		
    describe('on success', function() {
      var changeEventEmitted;
      beforeEach(function() {
        $httpBackend.flush();
        $httpBackend.whenDELETE('pending-transactions/t-332').respond();
        subject.transactions  = [{t1: true}, pendingTransaction, {t2: true}];
        scope.$on('pending-transactions-changed', function() {
          changeEventEmitted = true;
        });
        subject.reject();
        $httpBackend.flush();
      });
			
      it('should remove the transaction from pendingTransactions', function() {
        expect(subject.transactions.length).toEqual(2);
        expect(subject.transactions).toEqual([{t1: true}, {t2: true}]);
      });
			
      it('should emit pending-transactions-changed event', function() {
        expect(changeEventEmitted).toBeTruthy();
      });
    });
  });
});