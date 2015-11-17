//= require transactions/transactions.module.js
//= require_self
//= require_tree .

var Transaction = {
    incomeId: 1, incomeKey: 'income',
    expenseId: 2, expenseKey: 'expense',
    refundId: 3, refundKey: 'refund',
	transferId: undefined, transferKey: 'transfer',
	l10n: {}
};
Transaction.TypeIdByKey = {};
Transaction.TypeKeyById = {};
Transaction.TypeById = {};

Transaction.l10n[Transaction.incomeKey] = 'Income';
Transaction.l10n[Transaction.expenseKey] = 'Expense';
Transaction.l10n[Transaction.refundKey] = 'Refund';
Transaction.l10n[Transaction.transferKey] = 'Transfer';

jQuery.each([Transaction.incomeKey, Transaction.expenseKey, Transaction.refundKey, Transaction.transferKey], function(i, key) {
	var id = Transaction[key + 'Id'];
	var type = {id: id, key: key, t: function() { return Transaction.l10n[key]; }};
	Transaction.TypeIdByKey[key] = id;
	Transaction.TypeKeyById[id] = key;
	Transaction.TypeById[id] = type;
	Transaction[key] = type;
});
Transaction.regular = [Transaction.income, Transaction.expense, Transaction.refund];