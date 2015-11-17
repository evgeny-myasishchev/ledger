(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .directive('convertTransactionAction', convertTransactionAction);

  convertTransactionAction.$inject = ['$templateCache', '$compile', 'transactions'];

  function convertTransactionAction($templateCache, $compile, transactions) {
    var template = $templateCache.get('convert-transaction.html');
    var link = $compile(template);
    return {
      restrict: 'A',
      template: '',
      scope: {
        transaction: '='
      },
      link: function(scope, element, attrs) {
        var popoverParent;
        scope.convert = function() {
          transactions.convertType(scope.transaction, scope.type.id).then(function() {
            if(popoverParent) popoverParent.popover('hide');
          });
        }
        scope.cancel = function() {
          if(popoverParent) {
            popoverParent.popover('hide');
          }
        }
        element.click(function(e) {
          scope.transactionTypes = Transaction.regular;
          scope.type = null;
          popoverParent = $(element).parents('.btn-group');
          popoverParent.popover({
            html: true, 
            title: 'Moving transaction',
            trigger: 'manual',
            placement: 'left',
            content: function() {
              return link(scope, function() {});
            }
          });
          popoverParent.data('bs.popover').tip()
            .css('min-width', 300).css('max-width', 500);
          popoverParent.on('hidden.bs.popover', function(e) {
            popoverParent.popover('destroy');
          });
          popoverParent.popover('show');
        });
        scope.$on('$destroy', function() {
          if(popoverParent) popoverParent.popover('destroy');
        });
        // if(scope.transaction.transaction_id == '762d478d-71b9-4980-9fde-edafff484ba7')
        //  setTimeout(function() { element.trigger('click'); }, 100);
      }
    }
  }
})();