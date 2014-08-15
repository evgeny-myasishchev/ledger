describe('ledgerTags', function() {
  var scope;
  beforeEach(function() {
    module('ledgerDirectives');
	HomeHelpers.include(this);
	this.assignTags([
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
    return result;
  };

  it("should convert tag ids to tag names", function() {
    scope.tag_ids = '{100},{102}';
    var result = compile(scope);
    expect(result[0].innerHTML).toEqual('<div class="label label-info">Tag 100</div> <div class="label label-info">Tag 102</div>');
  });

  it("should ignore unknown tags", function() {
    scope.tag_ids = '{100},{111},{102}';
    var result = compile(scope);
    expect(result[0].innerHTML).toEqual('<div class="label label-info">Tag 100</div> <div class="label label-info">Tag 102</div>');
  });
  
  it("should ignore null tags", function() {
    scope.tag_ids = null;
    var result = compile(scope);
    expect(result[0].innerHTML).toEqual('');
  });
  
  it('should update tags on scope changes', function() {
      scope.tag_ids = '';
      var result = compile(scope);
	  scope.tag_ids = '{100},{102}';
	  scope.$digest();
	  expect(result[0].innerHTML).toEqual('<div class="label label-info">Tag 100</div> <div class="label label-info">Tag 102</div>');
  });
});