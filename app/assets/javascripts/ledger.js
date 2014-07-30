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
}).directive('ledgerTags', ['tags', function(tags) {
	var tagsById = {};
	jQuery.each(tags, function(index, tag) {
		tagsById['{' + tag.tag_id + '}'] = tag.name;
	});
	return {
		scope: {
			model: '=ngModel'
		},
		restrict: 'E',
		replace: false,
		link: function(scope, element, attrs) {
			if(scope.model == null) return;
			var tagIds = scope.model.split(',');
			var result = [];
			jQuery.each(tagIds, function(index, tagId) {
				var tagName = tagsById[tagId];
				if(tagName) result.push('<div class="label label-info">' + tagName + '</div>');
			});
			element.html(result.join(' '));
		}
	}
}]).directive('ledgerTagsInput', ['tags', function(tags) {
	var $ = jQuery;
	var tagsByName = {};
	var tagsById = {};
	$.each(tags, function(index, tag) {
		tagsByName[tag.name.toLowerCase()] = tag;
		tagsById[tag.tag_id] = tag;
	});
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
}]).directive('ldrBubbleEditor', ['$rootScope', '$timeout', '$pooledCompile', '$q', function($rootScope, $timeout, $pooledCompile, $q) {
	function getValue(scope, attrs) {
		return scope.$eval(attrs.value);
	};
	
	var datePickerCompilePool = $pooledCompile.newPool('<ldr-datepicker ng-model="date" />');
		
	var editorFactories = {
		'default': function(scope, element, attrs, resolve) {
			var input;
			var form = $('<form>').append(input = $('<input type="text" class="form-control">').val(getValue(scope, attrs))
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
			var datePicker, form = $('<form class="form-inline">');
			datePickerCompilePool.compile().then(function(dp) {
				datePicker = dp;
				datePicker.scope.date = getValue(scope, attrs);
				form.append(datePicker.element);
				var shownHandler;
				element.on('shown.bs.popover', shownHandler = function() {
					form.find('input').focus();
				});
				resolve({
					form: form,
					dispose: function() {
						datePicker.scope.$destroy();
						form.off();
						element.off('shown.bs.popover', shownHandler);
					},
					getNewValue: function() {
						return datePicker.scope.date;
					}
				});
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
			
			element.click(function() {
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
					});
				}
				//Toggle may not work here because of the focusout
				shown ? hidePopover() : showPopover();
			});
			
			scope.$on('$destroy', function() {
				element.popover('destroy');
			});
		}
	}
}]);