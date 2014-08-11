HomeHelpers = (function() {
	var activeAccount, actibeLedger;
	return {
		include: function(target) {
			target.assignActiveAccount = function(account) {
				activeAccount = account;
				inject(function(activeAccountResolver) {
					if(!jasmine.isSpy(activeAccountResolver.resolve)) {
						jasmine.currentEnv_.spyOn(activeAccountResolver, 'resolve').and.callFake(function() {
							return activeAccount;
						});
					}
				});
			};
			
			target.assignActiveLedger = function(l) {
				actibeLedger = l;
				inject(function(ledgers) {
					if(!jasmine.isSpy(ledgers.getActiveLedger)) {
						jasmine.currentEnv_.spyOn(ledgers, 'getActiveLedger').and.callFake(function() {
							return actibeLedger;
						});
					}
				});
			};
		}
	}
})();