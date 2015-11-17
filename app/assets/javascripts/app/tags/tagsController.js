!function($) {
	'use strict';

	angular
		.module('homeApp')
		.controller('TagsController', TagsController);

	TagsController.$inject = ['$scope', '$http', 'tags'];

	function TagsController($scope, $http, tags) {
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
	}
}(jQuery);