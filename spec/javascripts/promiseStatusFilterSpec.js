// Copied from https://github.com/evgeny-myasishchev/angular-promise-status
describe('promiseStatusFilter', function() {
  var subject, deferred, $rootScope;

  beforeEach(module('homeApp'));

  beforeEach(inject(function(_$rootScope_, $q, promiseStatusFilter) {
    $rootScope = _$rootScope_;
    subject = promiseStatusFilter;
    deferred = $q.defer();
  }));

  it('should set initial flags', function() {
    var status = subject(deferred.promise);
    expect(status).toEqual({
      inProgress: true,
      resolved: false,
      rejected: false
    });
  });

  it('should set resolved flags', function() {
    var status = subject(deferred.promise);
    deferred.resolve();
    $rootScope.$digest();
    expect(status).toEqual({
      inProgress: false,
      resolved: true,
      rejected: false
    });
  });

  it('should set rejected flags', function() {
    var status = subject(deferred.promise);
    deferred.reject();
    $rootScope.$digest();
    expect(status).toEqual({
      inProgress: false,
      resolved: false,
      rejected: true
    });
  });
});