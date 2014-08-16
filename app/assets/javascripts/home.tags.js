!function($) {
	var homeApp = angular.module('homeApp');
	
	homeApp.controller('TagsController', ['$scope', '$http', 'tags', function($scope, $http, tags) {
		$scope.tags = tags.getAll();
		
		$scope.create = function() {
			$scope.isCreated = false;
			return tags.create($scope.newTagName).then(function() {
				$scope.newTagName = null;
				$scope.isCreated = true;
			});
		};
		
		$scope.renameTag = function(tag, name) {
			return tags.rename(tag.tag_id, name);
		};
		
		$scope.removeTag = function(tag) {
			tags.remove(tag.tag_id);
		};
	}]);
}(jQuery);