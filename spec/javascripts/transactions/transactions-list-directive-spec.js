describe('transactions.transactionsList', function() {
	var scope, $httpBackend, $compile;
	var account1, account2;
	
	beforeEach(module('transactionsApp'));
	
	beforeEach(inject(function(_$httpBackend_, _$compile_, $rootScope){
		$httpBackend = _$httpBackend_;
		scope = $rootScope.$new();
		$compile = _$compile_;
		
		transactionsApp.config(['accountsProvider', function(accountsProvider) {
			accountsProvider.assignAccounts([
				account1 = {aggregate_id: 'a-1', sequential_number: 201, 'name': 'Cache UAH', 'balance': 10000, category_id: 1, is_closed: false},
				account2 = {aggregate_id: 'a-2', sequential_number: 202, 'name': 'PC Credit J', 'balance': 20000, category_id: 2, is_closed: false}
			]);
		}]);
	}));
	
	function compile() {
		var elem = angular.element('<div><script type="text/ng-template" id="transactions-list.html"></script>' +
			'<transactions-list></transactions-list></div>');
		var compiledElem = $compile(elem)(scope);
		scope.$digest();
		return compiledElem;
	};
	
	describe('adjust transaction', function() {
		var transaction;
		beforeEach(function() {
			compile();
			var date = new Date();
			date.setHours(date.getHours() -  10);
			
			transaction = {
				transaction_id: 't-223',
				account_id: 'a-1',
				amount: '100.23',
				tag_ids: [20],
				date: date.toJSON(),
				comment: 'Original comment'
			};
			
			scope.transactions = [
				{transaction1: true, date: date.toJSON()},
				{transaction2: true, date: date.toJSON()},
				transaction
			];
		});
		
		describe('adjustComment', function() {
			it('should post adjust-comment for given transaction', function() {
				$httpBackend.expectPOST('transactions/t-223/adjust-comment', function(data) {
					var command = JSON.parse(data).command;
					expect(command.comment).toEqual('New comment 223');
					return true;
				}).respond(200);
				var result = scope.adjustComment(transaction, 'New comment 223');
				$httpBackend.flush();
				expect(transaction.comment).toEqual('New comment 223');
				expect(result.then).toBeDefined();
			});
		});
		
		describe('adjustTags', function() {
			it('should post adjust-tags for given transaction', function() {
				$httpBackend.expectPOST('transactions/t-223/adjust-tags', function(data) {
					var command = JSON.parse(data).command;
					expect(command.tag_ids).toEqual([10, 20, 40]);
					return true;
				}).respond(200);
				var result = scope.adjustTags(transaction, [10, 20, 40]);
				$httpBackend.flush();
				expect(transaction.tag_ids).toEqual('{10},{20},{40}');
				expect(result.then).toBeDefined();
			});
		});
		
		describe('adjustDate', function() {
			it('should post adjust-date for given transaction', function() {
				var newDate = new Date();
				$httpBackend.expectPOST('transactions/t-223/adjust-date', function(data) {
					var command = JSON.parse(data).command;
					expect(command.date).toEqual(newDate.toJSON());
					return true;
				}).respond(200);
				var result = scope.adjustDate(transaction, newDate);
				$httpBackend.flush();
				expect(transaction.date).toEqual(newDate);
				expect(result.then).toBeDefined();
			});
		});
		
		describe('removeTransaction', function() {
			beforeEach(function() {
				$httpBackend.whenDELETE('transactions/t-223').respond(200);
			});

			it('should DELETE destroy for given transaction', function() {
				$httpBackend.expectDELETE('transactions/t-223').respond(200);
				var result = scope.removeTransaction(transaction);
				$httpBackend.flush();
				expect(result.then).toBeDefined();
			});

			describe('account.balance', function() {
				beforeEach(function() {
					account1.balance = 5000;
					transaction.amount = 1000;
				});

				it('should subtract for income or refund', function() {
					transaction.type_id = Transaction.incomeId;
					scope.removeTransaction(transaction);
					$httpBackend.flush();
					expect(account1.balance).toEqual(4000);

					transaction.type_id = Transaction.refundId;
					scope.removeTransaction(transaction);
					$httpBackend.flush();
					expect(account1.balance).toEqual(3000);
				});

				it('should add for expence', function() {
					transaction.type_id = Transaction.expenceId;
					scope.removeTransaction(transaction);
					$httpBackend.flush();
					expect(account1.balance).toEqual(6000);
				});
			})

			it('should remove the transaction from scope on success', function() {
				scope.removeTransaction(transaction);
				$httpBackend.flush();
				expect(scope.transactions).not.toContain(transaction);
			});
		});
		
		describe('adjustAmount', function() {
			it('should post adjust-amount for given transaction', function() {
				$httpBackend.expectPOST('transactions/t-223/adjust-amount', function(data) {
					var command = JSON.parse(data).command;
					expect(command.amount).toEqual(20043);
					return true;
				}).respond(200);
				var result = scope.adjustAmount(transaction, 20043);
				$httpBackend.flush();
				expect(transaction.amount).toEqual(20043);
				expect(result.then).toBeDefined();
			});

			it('should parse money string', function() {
				$httpBackend.expectPOST('transactions/t-223/adjust-amount', function(data) {
					var command = JSON.parse(data).command;
					expect(command.amount).toEqual(20043);
					return true;
				}).respond(200);
				var result = scope.adjustAmount(transaction, '200.43');
				$httpBackend.flush();
				expect(transaction.amount).toEqual(20043);
			});

			describe('update account balance', function() {
				beforeEach(function() {
					$httpBackend.expectPOST('transactions/t-223/adjust-amount').respond(200);
					account1.balance = 250;
					transaction.amount = 50;
				});

				it('should update the balance for income transaction', function() {
					transaction.type_id = Transaction.incomeId;
					scope.adjustAmount(transaction, 100);
					$httpBackend.flush();
					expect(account1.balance).toEqual(300);
				});

				it('should update the balance for refund transaction', function() {
					transaction.type_id = Transaction.refundId;
					scope.adjustAmount(transaction, 100);
					$httpBackend.flush();
					expect(account1.balance).toEqual(300);
				});

				it('should update the balance for expence transaction', function() {
					transaction.type_id = Transaction.expenceId;
					scope.adjustAmount(transaction, 100);
					$httpBackend.flush();
					expect(account1.balance).toEqual(200);
				});
			});
		});
	});
	
	describe("getTransferAmountSign", function() {
		var transaction;
		beforeEach(function() {
			transaction = {type_id: -100, is_transfer: true};
			compile();
		});

		it("should return + sign for transfer income", function() {
			transaction.type_id = 1;
			expect(scope.getTransferAmountSign(transaction)).toEqual('+');
		});

		it("should return - sign for transfer expence", function() {
			transaction.type_id = 2;
			expect(scope.getTransferAmountSign(transaction)).toEqual('-');
		});

		it("should return empty for other transactions", function() {
			transaction.type_id = 2;
			transaction.is_transfer = false;
			expect(scope.getTransferAmountSign(transaction)).toBeNull();
		});
	});
	
	describe('tti filter', function() {
		var filter;
		beforeEach(function() {
			transaction = {type_id: -100, is_transfer: false};
			inject(function(ttiFilter) { filter = ttiFilter});
		});
		it('should return transfer icon if transaction is transfer', function() {
			transaction.is_transfer = true;
			expect(filter(transaction)).toEqual('glyphicon glyphicon-transfer');
			expect(filter({type: Transaction.transferKey})).toEqual('glyphicon glyphicon-transfer');
		});
		it('should return income specific icon if transaction is income', function() {
			transaction.type_id = 1;
			expect(filter(transaction)).toEqual('glyphicon glyphicon-plus');
			expect(filter({type: Transaction.incomeKey})).toEqual('glyphicon glyphicon-plus');
		});
		it('should return expence specific icon if transaction is expence', function() {
			transaction.type_id = 2;
			expect(filter(transaction)).toEqual('glyphicon glyphicon-minus');
			expect(filter({type: Transaction.expenceKey})).toEqual('glyphicon glyphicon-minus');
		});
		it('should return refund specific icon if transaction is refund', function() {
			transaction.type_id = 3;
			expect(filter(transaction)).toEqual('glyphicon glyphicon-share-alt');
			expect(filter({type: Transaction.refundKey})).toEqual('glyphicon glyphicon-share-alt');
		});
	});
});