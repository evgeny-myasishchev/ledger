describe('promiseStatusFilter', function() {
  var subject, deferred, status, $rootScope;

  beforeEach(module('homeApp'));

  beforeEach(inject(function(_$rootScope_, $q, promiseStatusFilter) {
    $rootScope = _$rootScope_;
    subject = promiseStatusFilter;
    deferred = $q.defer();
    status = {};
  }));

  it('should set initial flags', function() {
    subject(deferred.promise, status);    
    expect(status).toEqual({
      inProgress: true,
      resolved: false,
      rejected: false
    });
  });

  it('should set resolved flags', function() {
    subject(deferred.promise, status);
    deferred.resolve();
    $rootScope.$digest();
    expect(status).toEqual({
      inProgress: false,
      resolved: true,
      rejected: false
    });
  });

  it('should set rejected flags', function() {
    subject(deferred.promise, status);
    deferred.reject();
    $rootScope.$digest();
    expect(status).toEqual({
      inProgress: false,
      resolved: false,
      rejected: true
    });
  });
});