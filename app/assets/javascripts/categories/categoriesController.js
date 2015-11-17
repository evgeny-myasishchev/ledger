!function($) {
	'use strict';
	
	angular.module('homeApp')
		.controller('CategoriesController', CategoriesController);

	CategoriesController.$inject = ['$scope', '$http', 'ledgers', 'accounts', ];

	function CategoriesController($scope, $http, ledgers, accounts) {
		$scope.categories = accounts.getAllCategories();

		$scope.createCategory = function() {
			$scope.isCreated = false;
			return $http.post('ledgers/' + ledgers.getActiveLedger().aggregate_id + '/categories', {
				name: $scope.newCategoryName
			}).success(function(data) {
				accounts.addCategory(data.category_id, $scope.newCategoryName);
				$scope.newCategoryName = null;
				$scope.isCreated = true;
			});
		};

		$scope.renameCategory = function(category, name) {
			return $http.put('ledgers/' + ledgers.getActiveLedger().aggregate_id + '/categories/' + category.category_id, {
				name: name
			}).success(function(data) {
				category.name = name;
			});
		};

		$scope.removeCategory = function(category) {
			return $http.delete('ledgers/' + ledgers.getActiveLedger().aggregate_id + '/categories/' + category.category_id)
			.success(function(data) {
				accounts.removeCategory(category);
			});
		};
	}
}(jQuery);