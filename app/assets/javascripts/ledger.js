var Transaction = {
    incomeId: 1, incomeKey: 'income',
    expenceId: 2, expenceKey: 'expence',
    refundId: 3, refundKey: 'refund',
	transferKey: 'transfer'
};

angular.module('ErrorLogger', []).factory('$exceptionHandler', function () {
	return function errorCatcherHandler(exception, cause) {
		console.error(exception);
	};
});

var ledgerDirectives = angular.module('ledgerDirectives', ['ledgerHelpers']).directive('ldrDatepicker', function() {
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
}).directive('ledgerTags', ['tags', 'tagsHelper', function(tags, tagsHelper) {
	var tagsById = tagsHelper.indexById(tags);
	
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
}]).directive('ledgerTagsInput', ['tags', 'tagsHelper', function(tags, tagsHelper) {
	var $ = jQuery;
	var tagsByName = tagsHelper.indexByName(tags);
	var tagsById = tagsHelper.indexById(tags);
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
					$.each(newTagIds, function(index, newTagId) {
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
}]).directive('ldrBubbleEditor', ['tags', 'tagsHelper', 'money', function(tags, tagsHelper, money) {
	function getValue(scope, attrs) {
		return scope.$eval(attrs.value);
	};
	
	var formatters = {
		money: money.formatInteger
	}
	
	function format(value, attrs) {
		if(attrs.format) {
			return formatters[attrs.format](value);
		} else {
			return value;
		}
	}
	
	var editorFactories = {
		'default': function(scope, element, attrs, resolve) {
			var input, value = getValue(scope, attrs);
			var form = $('<form>').append(input = $('<input type="text" class="form-control">').val(format(value, attrs))
			.on('focusout', function() {
				element.popover('hide');
			}));
			var shownHandler;
			element.on('shown.bs.popover', shownHandler = function() {
				input.focus();
			});
			resolve({
				form: form,
				dispose: function() {
					form.off();
					element.off('shown.bs.popover', shownHandler);
				},
				getNewValue: function() { return input.val(); }
			});
		},
		'date': function(scope, element, attrs, resolve) {
			var datepicker, input, form = $('<form class="form-inline">')
				.append(datepicker = $('<div class="input-group">')
					.append(input = $('<input type="text" class="form-control" />'))
					.append('<span class="input-group-addon"><span class="glyphicon glyphicon-calendar"></span></span>')
					.datetimepicker()
				)
				.on('dp.show', function() {
					input.focus(); //The dp takes focus when showing. Restoring the focus to avoiding hidding.
				})
				.on('focusout', function() {
					setTimeout(function() {
						if(!input.is(':focus')) element.popover('hide');
					}, 100); //Using such a timeout to let focus to be restored if needed (see db.show handler above)
				});
			datepicker = datepicker.data('DateTimePicker');
			var shownHandler;
			element.on('shown.bs.popover', shownHandler = function() {
				input.focus();
			});
			datepicker.setDate(getValue(scope, attrs));
			resolve({
				form: form,
				dispose: function() {
					form.off();
					element.off('shown.bs.popover', shownHandler);
					datepicker.destroy();
				},
				getNewValue: function() {
					return datepicker.getDate().toDate();
				}
			});
		},
		'tags': function(scope, element, attrs, resolve) {
			var tagsByName = tagsHelper.indexByName(tags);
			var tagsById = tagsHelper.indexById(tags);
			
			var input, form = $('<form class="form-inline" style="width: 200px">')
				.append($('<div class="form-group" style="display: block;">')
					.append(input = $('<input type="text" class="form-control" placeholder="Tags" style="width: 100%">'))
				);
			input.tagsinput({
				confirmKeys: [188],
				tagClass: function(tag) {
					return tagsByName[tag.toLowerCase()] ? 'label label-info' : 'label label-warning';
				}
			});
			form.find('div.bootstrap-tagsinput').css({display: 'block', marginBottom: 0});
			var tagsinput = input.data('tagsinput');
			var actualInput = input.tagsinput('input');
			actualInput.keypress(function(e) {
				//Forcing refresh on enter
				if(e.keyCode == 13) {
					tagsinput.add(actualInput.val());
					actualInput.val('');
					form.trigger('submit');
				}
			}).on('focusout', function() {
				element.popover('hide');
			});
			input.on('change', function() {
				var selectedTagNames = input.tagsinput('items');
				if(selectedTagNames.length) {
					actualInput.removeAttr('placeholder');
				} else {
					actualInput.attr('placeholder', 'Tags');
				}
			});
			
			//Set initial value
			var tagIds = tagsHelper.bracedStringToArray(getValue(scope, attrs));
			$.each(tagIds, function(index, tagId) {
				input.tagsinput('add', tagsById[tagId].name);
			});

			var shownHandler;
			element.on('shown.bs.popover', shownHandler = function() {
				form.find('input').focus();
			});
			resolve({
				form: form,
				dispose: function() {
					form.off();
					input.off();
					element.off('shown.bs.popover', shownHandler);
					tagsinput.destroy();
				},
				getNewValue: function() {
					var selectedTagNames = input.tagsinput('items');
					var tagIds = [];
					$.each(selectedTagNames, function(index, tagName) {
						var tag = tagsByName[tagName.toLowerCase()];
						if(tag) tagIds.push(tag.tag_id);
					});
					return tagIds;
				}
			});
		}
	}
	
	return {
		restrict: 'A',
		link: function(scope, element, attrs) {
			var editorType = attrs.ldrBubbleEditor || 'default';
			var initialized, showing, shown;
			var editor = null;
			
			function buildEditor(resolve) {
				editorFactories[editorType](scope, element, attrs, function(edt) {
					edt.form.keypress(function(e) {
						if(e.keyCode == 27) hidePopover();
					})
					.on('submit', function() {
						scope.$eval(attrs.submit, {newValue: edt.getNewValue()}).success(function() {
							hidePopover(element);
						});
					});
					resolve(edt);
				});
			}
			
			var showing = false;
			function showPopover() {
				if(!shown && !showing) {
					showing = true;
					buildEditor(function(edt) {
						editor = edt;
						element.popover('show');
					});
				}
			}
	
			function hidePopover() {
				if(shown) {
					element.popover('hide');
				}
			}
			
			function evalFinally() {
				if(attrs.finally) {
					scope.$eval(attrs.finally);
					scope.$digest();
				}
			}
			
			var trigger = function() {
				if(!initialized) {
					initialized = true;
					element.popover({
							trigger: 'manual',
							html: true,
							placement: 'auto top',
							container: 'body',
							content: function() {
								return editor.form;
							}
					})
					.on('shown.bs.popover', function() {
						shown = true;
						showing = false;
					})
					.on('hidden.bs.popover', function() {
						if(!shown) return;
						shown = false
						editor.dispose()
						editor = null;
						evalFinally();
					});
				}
				//Toggle may not work here because of the focusout
				shown ? hidePopover() : showPopover();
			};
			
			if(attrs.triggerOn) {
				scope.$watch(attrs.triggerOn, function(newValue) {
					if(newValue) trigger();
				});
			} else {
				element.click(trigger);
			}
			
			scope.$on('$destroy', function() {
				element.popover('destroy');
			});
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
		
		this.$get = function() {
			return {
				getActiveLedger: function() {
					return ledgers[0];
				}
			}
		}
	});
}();