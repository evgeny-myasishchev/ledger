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
	
	ledgerHelpers.provider('search', function() {
		this.$get = ['tags', 'tagsHelper', 'money', function(tags, tagsHelper, money) {
			var tryParseAmount = function(expression) {
				try {
					var amount = money.parse(expression);
					return { amount: amount };
				} catch(e) { } //Doing nothing. It was not a money.
				return false;
			};
			var tryParseTagIds = function(expression) {
				var tagsByName = tagsHelper.indexByName(tags.getAll());
				var parts = expression.split(',');
				var tagIds = [];
				$.each(parts, function(index, part) {
					part = part.trim().toLowerCase();
					var tag = tagsByName[part];
					if(tag) tagIds.push(tag.tag_id);
					else return false;
				});
				if(tagIds.length) return {tag_ids: tagIds};
				return false;
			};
			return {
				parseExpression: function(expression) {
					var criteria;
					if(criteria = tryParseAmount(expression)) return criteria;
					if(criteria = tryParseTagIds(expression)) return criteria;
					//TODO: Implement dates parsing
					
					return { comment: expression };
				}
			}
		}];
	});
	
	ledgerHelpers.provider('money', function() {
		var defaults = {
			separator: '.', //decimal separator
			delimiter: ',' //thousands delimiter
		};
		var options = jQuery.extend({}, defaults);
		this.configure = function(opts) {
			jQuery.extend(options, defaults, opts);
		};
		
		var toFiguresArray = function(number) {
			var rest = Math.abs(number);
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
				toNumber: function(integerMoney) {
					return integerMoney / 100;
				},
				
				toIntegerMoney: function(number) {
					return Math.floor(number * 100);
				},
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
					if(number < 0) figures.unshift('-');
					return figures.join('');
				},
				parse: function(money) {
					var type = typeof(money);
					if(type == 'number') {
						if(money % 1 != 0) throw new Error('Can not parse ' + money + '. Parsing fractional numbers is not supported.');
						return money;
					} else if(type != 'string') {
						throw new Error('Can not parse. String or number is expected. Got ' + type + '.')
					}
					if(!money) throw new Error("Can not parse '" + money + "'. Invalid money string.");
					var parts = money.replace(/ /g, '').split(options.separator);
					if(parts.length == 0 || parts.length > 2) throw new Error("Can not parse '" + money + "'. Invalid money string.");
					var integer = parts[0].replace(new RegExp(options.delimiter, 'g'), '');
					var fraction = parts.length == 2 ? parts[1] : '00';
					if(fraction.length == 0) throw new Error("Can not parse '" + money + "'. Fractional part is missing.");
					else if(fraction.length == 1) fraction = fraction + '0';
					else if(fraction.length > 2) throw new Error("Can not parse '" + money + "'. Fractional part is longer than two dights.");
					var result = parseInt(integer + fraction);
					if(isNaN(result)) throw new Error("Can not parse '" + money + "'. Invalid money string.");
					return result;
				}
			}
		}
	});
	
	ledgerHelpers.filter('money', ['money', function(money) {
		return function(input) {
			if(typeof(input) == 'undefined') return input;
			return money.formatInteger(input);
		}
	}]);
	
	ledgerHelpers.filter('then', [function() {
		return function(promise, scope, expression) {
			var that = this;
			return promise.then(function() {
				scope.$eval(expression, {});
			});
		}
	}]);
	
	ledgerHelpers.provider('units', function() {
		this.$get = function() {
			return {
				convert: function(from, to, amount) {
					if(from == 'g' && to == 'ozt') {
						return Math.floor((amount / 31.1034768));
					} else {
						throw "Conversion from '" + from + "' to '" + to + "' is not supported.";
					}
				}
			}
		}
	});
})();