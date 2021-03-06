angular.module('ErrorHandler', [])
.config(['$httpProvider', function($httpProvider) {
	$httpProvider.interceptors.push(['$q', '$rootScope', function($q, $rootScope) {
		return {
			'responseError': function(rejection) {
				$rootScope.$broadcast('http.unhandled-server-error', {
					status: rejection.status,
					statusText: rejection.statusText
				});
				return $q.reject(rejection);
			}
		};
	}]);
}])
.factory('$exceptionHandler', function () {
	return function errorCatcherHandler(exception, cause) {
		console.error(exception);
	};
}).directive('ldrErrorsNotifier', [function() {
	return {
		restrict: 'E',
		scope: {},
		templateUrl: 'application-error.html',
		link: function(scope, element, attrs) {
			var modal = element.find('div.modal');
			modal.modal({
				show:false
			});
			scope.$on('http.unhandled-server-error', function(evt, data) {
				scope.title = data.status + ' ' + data.statusText;
				modal.modal('show');
			});
		}
	};
}]);

var ledgerDirectives = angular.module('ledgerDirectives', ['ledgerHelpers', 'tagsProvider'])
.directive('autofocus', function() {
	return {
		restrict: 'A',
		link: function(scope, element, attrs) {
			if(attrs.autofocus) scope.$watch(attrs.autofocus, function(newVal, oldVal) {
				//Using some moderate timeout to let the element be shown.
				if(newVal) setTimeout(function() {
					element.focus();
				}, 100);
			});
		}
	}
})
.directive('ldrDatepicker', function() {
	return {
		restrict: 'E',
		scope: {
			date: '=ngModel'
		},
		template: '<input type="text" class="form-control" placeholder="Date"><span style="cursor: pointer;" class="input-group-addon"><i class="glyphicon glyphicon-calendar"></i></span>',
		link: function(scope, element, attrs) {
			element.addClass('input-group');
			var input = element.find('input');
			var datePicker = element.datetimepicker({
				language: 'en-gb',
				sideBySide: false
			}).data('DateTimePicker');
			var handlingChange = false;
			scope.$watch('date', function(newValue) {
				datePicker.setDate(newValue);
			});
			element.on('dp.change', function(e) {
				scope.date = datePicker.getDate().toDate();
			})
			input.keypress(function(e) {
				if(e.keyCode == 13) {
					datePicker.hide();
				}
			})
			scope.$on('$destroy', function() {
				datePicker.destroy();
			});
			datePicker.setDate(scope.date);
		}
	}
})
.directive('ledgerTags', ['tags', 'tagsHelper', function(tags, tagsHelper) {
	var tagsById = tagsHelper.indexById(tags.getAll());
	
	var updateTags = function(element, wrappedTagIds) {
		var tagIds = tagsHelper.bracedStringToArray(wrappedTagIds);
		var result = [];
		jQuery.each(tagIds, function(index, tagId) {
			var tag = tagsById[tagId];
			if(tag) result.push('<div class="label label-info">' + tag.name + '</div>');
		});
		element.html(result.join(' '));
	};
	
	return {
		scope: {
			model: '=ngModel'
		},
		restrict: 'E',
		replace: false,
		link: function(scope, element, attrs) {
			scope.$watch('model', function() {
				updateTags(element, scope.model);
			});
			if(scope.model == null) return;
			updateTags(element, scope.model);
		}
	}
}])
.directive('ledgerTagsInput', ['tags', 'tagsHelper', function(tags, tagsHelper) {
	var $ = jQuery;
	var tagsByName = tagsHelper.indexByName(tags.getAll());
	var tagsById = tagsHelper.indexById(tags.getAll());
	return {
		restrict: 'E',
		scope: {
			model: '=ngModel'
		},
		template: '<input type="text" class="form-control" placeholder="Tags" style="width: 100%">',
		link: function(scope, element, attrs) {
			var input = element.find('input');
			input.tagsinput({
				confirmKeys: [188],
				tagClass: function(tag) {
					return tagsByName[tag.toLowerCase()] ? 'label label-info' : 'label label-warning';
				}
			});
			var actualInput = input.tagsinput('input');
			if(attrs.tabindex) {
				element.attr('tabindex', null);
				actualInput.attr('tabindex', attrs.tabindex);
			}
			actualInput.keypress(function(e) {
				//Forcing refresh on enter
				if(e.keyCode == 13) {
					input.data('tagsinput').add(actualInput.val());
					actualInput.val('');
				}
			});
			var handlingModelChanges = false;
			scope.$watch('model', function(newTagIds) {
				try {
					handlingModelChanges = true;
					input.tagsinput('removeAll');
					if(newTagIds) $.each(newTagIds, function(index, newTagId) {
						var tag = tagsById[newTagId];
						if(tag) input.tagsinput('add', tag.name);
					});
				} finally {
					handlingModelChanges = false;
				}
			});
			input.on('change', function() {
				var selectedTagNames = input.tagsinput('items');
				if(selectedTagNames.length) {
					actualInput.removeAttr('placeholder');
				} else {
					actualInput.attr('placeholder', 'Tags');
				}
				if(handlingModelChanges) return;
				var tagIds = [];
				$.each(selectedTagNames, function(index, tagName) {
					var tag = tagsByName[tagName.toLowerCase()];
					if(tag) tagIds.push(tag.tag_id);
				});
				scope.model = tagIds;
				scope.$digest();
			});
			//TODO: Consider cleanup. Sample: element.on('$destroy', ...)
		}
	}
}]);

!function() {
	var ledgersProvider = angular.module('ledgersProvider', []);
	ledgersProvider.provider('ledgers', function() {
		var ledgers = [];
		this.assignLedgers = function(l) {
			ledgers = l;
		};
		
		var currencyRates = {};
		var resolveCachedRate = function(ledger, deferred) {
			deferred.resolve(currencyRates[ledger.aggregate_id]);
		};
		this.$get = ['$http', '$q', '$rootScope', function($http, $q, $rootScope) {
			var provider;
			$rootScope.$on('account-added', function(event, account) {
				var activeledger = provider.getActiveLedger();
				if(!activeledger) return;
				var rates = currencyRates[activeledger.aggregate_id];
				if(rates && !rates[account.currency_code]) {
					delete currencyRates[activeledger.aggregate_id];
				}
			});
			return provider = {
				getActiveLedger: function() {
					return ledgers[0];
				},
				loadCurrencyRates: function() {
					var activeLedger = provider.getActiveLedger();
					if(currencyRates[activeLedger.aggregate_id]) {
						return currencyRates[activeLedger.aggregate_id];
					} else {
						var deferred = $.Deferred();
						currencyRates[activeLedger.aggregate_id] = deferred.promise();
						$http.get('ledgers/' + activeLedger.aggregate_id + '/currency-rates.json').success(function(rates) {
							var byFrom = {};
							$.each(rates, function(index, rate) {
								byFrom[rate.from] = rate;
							});
							deferred.resolve(byFrom);
						});
						return deferred.promise();
					}
				}
			}
		}]
	});
	
	ledgersProvider.filter('activeLedger', ['ledgers', function(ledgers) {
		return function(attribute) {
			return ledgers.getActiveLedger()[attribute];
		};
	}]);
	
	var tagsProvider = angular.module('tagsProvider', ['ledgersProvider']);
	tagsProvider.provider('tags', function() {
		var tags = [];
		this.assignTags = function(value) {
			tags = value;
		};
		this.$get = ['$http', 'ledgers', function($http, ledgers) {
			return {
				getAll: function() {
					return tags;
				},
				create: function(name) {
					return $http.post('ledgers/' + ledgers.getActiveLedger().aggregate_id + '/tags', {
						name: name
					}).success(function(data) {
						tags.push({tag_id: data.tag_id, name: name});
					});
				},
				rename: function(tag_id, name) {
					return $http.put('ledgers/' + ledgers.getActiveLedger().aggregate_id + '/tags/' + tag_id, {
						name: name
					}).success(function(data) {
						$.each(tags, function(index, tag) {
							if(tag.tag_id == tag_id) {
								tag.name = name;
								return false;
							}
						});
					});
				},
				remove: function(tag_id) {
					return $http.delete('ledgers/' + ledgers.getActiveLedger().aggregate_id + '/tags/' + tag_id).success(function(data) {
						var tagIndex;
						$.each(tags, function(index, tag) {
							if(tag.tag_id == tag_id) {
								tagIndex = index;
								return false;
							}
						});
						tags.splice(tagIndex, 1);
					});;
				}
			}
		}];
	});
}();

angular.module('UUID', []).factory('newUUID', function () {
	var newUUID = function() {
		return uuid.v4();
	};
	return newUUID;
});