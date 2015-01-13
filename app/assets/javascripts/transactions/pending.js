!function() {
	var transactionsApp = angular.module('transactionsApp');
	
	transactionsApp.provider('pendingTransactions', function() {
		var pendingTransactionsCount = 0;
		
		this.setPendingTransactionsCount = function(value) {
			pendingTransactionsCount = value;
		};
		
		this.$get = [function() {
			return {
				getCount: function() {
					return pendingTransactionsCount;
				},
				
				approve: function(pendingTransaction, approvalData) {
					
				}
			}
		}];
	});
	
	transactionsApp.controller('PendingTransactionsController', ['$scope', '$http', 'accounts', 'money', 'newUUID',
	function ($scope, $http, accounts, money, newUUID) {
	}]);
}();