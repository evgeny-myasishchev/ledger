describe('ledgerTags', function() {
  var scope;
  beforeEach(function() {
    module('homeApp');
    homeApp.constant('tags', [
      {tag_id: 100, name: 'Tag 100'},
      {tag_id: 101, name: 'Tag 101'},
      {tag_id: 102, name: 'Tag 102'}
    ]);    
    inject(function($rootScope) {
      scope = $rootScope.$new();
    });
  });

  function compile(scope) {
    var result;
    inject(function($compile) {
      result = $compile('<ledger-tags ng-model="tag_ids" />')(scope);
    });
    scope.$digest();
    console.log(result);
    return result;
  };

  it("should convert tag ids to tag names", function() {
    scope.tag_ids = '{100},{102}';
    var result = compile(scope);
    expect(result[0].innerHTML).toEqual('Tag 100, Tag 102');
  });

  it("should ignore unknown tags", function() {
    scope.tag_ids = '{100},{111},{102}';
    var result = compile(scope);
    expect(result[0].innerHTML).toEqual('Tag 100, Tag 102');
  });
});