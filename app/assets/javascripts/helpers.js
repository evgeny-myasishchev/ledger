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
	
	ledgerHelpers.provider('money', function() {
		var options = {
			separator: '.', //decimal separator
			delimiter: ',' //thousands delimiter
		};
		this.configure = function(opts) {
			jQuery.extend(options, opts);
		};
		
		var toFiguresArray = function(number) {
			var rest = number;
			var figures = [];
			do {
				remeinder = rest % 10;
				figures.unshift(remeinder);
				rest = (rest - remeinder) / 10;
			} while(rest > 0);
			return figures;
		}
		
		this.$get = function() {
			return {
				formatInteger: function(number) {
					if(number % 1 != 0) throw new Error(number + ' is not integer.');
					var figures = toFiguresArray(number);
					
					//Adding leading zeros if needed
					while(figures.length < 3) figures.unshift(0);
					
					//Adding separator
					figures.splice(figures.length - 2, 0, options.separator);
					
					//Adding thousands delimiters
					if(figures.length > 6) {
						for(var i = figures.length - 6; i > 0; i = i - 3) {
							figures.splice(i, 0, options.delimiter);
						}
					}
					return figures.join('');
				}
			}
		}
	});
})();