(function () {  
  'use strict';

  angular
    .module('transactionsApp')
    .directive('moveTransactionAction', moveTransactionAction);

  moveTransactionAction.$inject = ['$templateCache', '$compile', 'accounts', 'transactions'];

  function moveTransactionAction($templateCache, $compile, accounts, transactions) {
    var template = $templateCache.get('move-transaction.html');
    var link = $compile(template);
    return {
      restrict: 'A',
      template: '',
      scope: {
        transaction: '='
      },
      link: function(scope, element, attrs) {
        var popoverParent;
        scope.move = function() {
          transactions.moveTo(scope.transaction, scope.targetAccount).then(function() {
            if(popoverParent) popoverParent.popover('hide');
          });
        }
        scope.cancel = function() {
          if(popoverParent) {
            popoverParent.popover('hide');
          }
        }
        element.click(function(e) {
          scope.accounts = accounts.getAllOpen();
          scope.targetAccount = null;
          if(scope.transaction.is_transfer) {
            scope.dontMoveTo = [
              accounts.getById(scope.transaction.sending_account_id),
              accounts.getById(scope.transaction.receiving_account_id)
            ];
          } else {
            scope.dontMoveTo = accounts.getById(scope.transaction.account_id);
          }
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
        // if(scope.transaction.transaction_id == 'a571a773-8df0-4d1a-a254-1ae3706894b4')
        //  setTimeout(function() { element.trigger('click'); }, 100);
      }
    }
  }
})();