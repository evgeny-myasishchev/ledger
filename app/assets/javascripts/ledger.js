angular.module('ErrorLogger', []).factory('$exceptionHandler', function () {
	return function errorCatcherHandler(exception, cause) {
		console.error(exception);
	};
});

var ledgerDirectives = angular.module('ledgerDirectives', []).directive('ldrDatepicker', function() {
	return {
		restrict: 'E',
		scope: {
			date: '=ngModel'
		},
		template: '<input type="text" class="form-control" placeholder="Date">',
		link: function(scope, element, attrs) {
			var input = element.find('input');
			var datePicker = input.datetimepicker({
				language: 'en-gb',
				sideBySide: true
			}).data('DateTimePicker');
			var handlingChange = false;
			scope.$watch('date', function(newValue) {
				datePicker.setDate(newValue);
			});
			input.on('dp.change', function(e) {
				scope.date = datePicker.getDate().toDate();
			})
			input.keypress(function(e) {
				if(e.keyCode == 13) {
					datePicker.hide();
				}
			})
			.on('$destroy', function() {
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
}]).directive('ldrBubbleEditor', function() {
	function getValue(scope, attrs) {
		return scope.$eval(attrs.value);
	};
	
	return {
		restrict: 'A',
		link: function(scope, element, attrs) {
			element.click(function() {
				var initialized;
				if(!initialized) {
					initialized = true;
					element.popover({
							trigger: 'manual', 
							html: true,
							placement: 'auto top',
							content: function() {
								var form = $('<form>')
									.append(input = $('<input type="text" class="form-control">').val(getValue(scope, attrs))
										.on('focusout', function() {
											element.popover('hide');
										})
										.keypress(function(e) {
											if(e.keyCode == 27) popover.popover('hide');
										})
									).on('submit', function() {
										scope.$eval(attrs.submit, {newValue: input.val()}).success(function() {
											element.popover('hide');
										});
									});
								return form;
							}
						})
						.on('shown.bs.popover', function() {
							input.focus();
						});
					element.on('$destroy', function() {
						element.popover('destroy');
					});
				}
				element.popover('show');
			});
		}
	}
});