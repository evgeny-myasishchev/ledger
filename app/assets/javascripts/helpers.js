(function() {
	var ledgerHelpers = angular.module('ledgerHelpers', []);
	ledgerHelpers.service('tagsHelper', function() {
		return {
			indexByName: function(tags) {
				var tagsByName = {};
				$.each(tags, function(index, tag) {
					tagsByName[tag.name.toLowerCase()] = tag;
				});
				return tagsByName;
			},
			indexById: function(tags) {
				var tagsById = {};
				$.each(tags, function(index, tag) {
					tagsById[tag.tag_id] = tag;
				});
				return tagsById;
			},
			bracedStringToArray: function(string) {
				return [4];
			}
		};
	});
})();