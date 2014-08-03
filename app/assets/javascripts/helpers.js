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
				if(string) {
					var braceStart, result = [];
					for(var i = 0; i < string.length; i++) {
						var char = string[i];
						if(char == '{') braceStart = i + 1;
						if(char == '}')  {
							result.push(parseInt(string.substring(braceStart, i)));
						}
					}
					return result;
				} else {
					return [];
				}
			},
			arrayToBracedString: function(tag_ids) {
				result = []
				for(var i = 0; i < tag_ids.length; i++) result.push('{' + tag_ids[i] + '}');
				return result.join(',');
			}
		};
	});
})();