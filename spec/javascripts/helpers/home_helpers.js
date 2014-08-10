HomeHelpers = (function() {
	var activeAccount;
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
		}
	}
})();