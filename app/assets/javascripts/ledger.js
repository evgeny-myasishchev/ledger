angular.module('ErrorLogger', []).factory('$exceptionHandler', function () {
	return function errorCatcherHandler(exception, cause) {
		console.error(exception);
	};
});

var ledgerDirectives = angular.module('ledgerDirectives', []).directive('bsDatepicker', function() {
	return {
		require: '?ngModel',
		link: function(scope, element, attrs, ngModel) {
			var datePicker;
			ngModel.$render = function() {
				datePicker = element.datepicker().data('datepicker');
				datePicker.setDate(ngModel.$viewValue);
			};
			element.on('change', function() {
				ngModel.$setViewValue(datePicker.getDate());
			});
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
		}
	}
}]);