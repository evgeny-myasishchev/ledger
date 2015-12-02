(function() {
  'use strict';

  angular
    .module('transactionsApp')
    .directive('showTransactionInfo', showTransactionInfo);

  showTransactionInfo.$inject = ['$templateCache', '$compile', 'accounts', 'transactions'];

  function showTransactionInfo($templateCache, $compile, accounts, transactions) {
    var template = $templateCache.get('app/transactions/transaction-info.html');
    var templateLink = $compile(template);
    var handleMouseEvents = function(scope, element) {
      element.mouseenter(function() {
        element.tooltip({
          html: true,
          trigger: 'manual',
          container: 'body',
          title: function() {
            var linked = templateLink(scope, function() {});
            scope.$digest();
            return linked;
          }
        });
        element.on('hidden.bs.tooltip', function(e) {
          element.tooltip('destroy');
        });
        element.tooltip('show');
      });
      element.mouseleave(function() {
        element.tooltip('destroy');
      })
      scope.$on('$destroy', function() {
        element.tooltip('destroy');
      });
    }

    return {
      restrict: 'A',
      template: '',
      link: function(scope, element) {
        if(scope.transaction) {
          handleMouseEvents(scope, element);
        }
      }
    }
  }
})();