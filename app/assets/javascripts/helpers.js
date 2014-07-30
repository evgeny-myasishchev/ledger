(function() {
	var ledgerHelpers = angular.module('ledgerHelpers', []);
	ledgerHelpers.service('$pooledCompile', ['$rootScope', '$timeout', '$compile', '$q', function($rootScope, $timeout, $compile, $q) {
		var Pool = function(content) {
			var latest;
			var scheduleLatestCompile = function(resolve) {
				$timeout(function() {
					var scope = $rootScope.$new();
					var element = $compile(content)(scope);
					latest = { scope: scope, element: element };
					if(resolve) resolve();
					if(latest == null) scheduleLatestCompile();
				}, 10);
			};
			scheduleLatestCompile(); //To have one ready

			this.compile = function() {
				var defered = $q.defer();
				if(latest) {
					defered.resolve(latest);
					scheduleLatestCompile();
				} else {
					scheduleLatestCompile(function() {
						defered.resolve(latest);
						latest = null;
					});
				}
				return defered.promise;
			};
		};
		return {
			newPool: function(content) {
				return new Pool(content);
			}
		}
	}]);
})();