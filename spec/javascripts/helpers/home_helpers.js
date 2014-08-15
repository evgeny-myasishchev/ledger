HomeHelpers = (function() {
	var activeAccount, actibeLedger;
	return {
		include: function(target) {
			target.assignTags = function(value) {
				inject(function(tags) {
					spyOn(tags, 'getAll').and.returnValue(value);
				});
			};
			
			target.assignActiveAccount = function(account) {
				activeAccount = account;
				inject(function(accounts) {
					if(!jasmine.isSpy(accounts.getActive)) {
						jasmine.currentEnv_.spyOn(accounts, 'getActive').and.callFake(function() {
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