describe("money", function() {
	var subject;
	beforeEach(function() {
		module('ledgerHelpers');
		angular.module('ledgerHelpers').config(function(moneyProvider) {
			moneyProvider.configure({
				separator: '|', delimiter: '-'
			});
		});
		inject(function(money) { subject = money; });
	});
	
	describe('formatInteger', function() {
		it('should format zero', function() { 
			expect(subject.formatInteger(0)).toEqual('0|00');
		});
		
		it('should format integers less than 100', function() {
			// expect(subject.formatInteger(1)).toEqual('0|01');
			expect(subject.formatInteger(99)).toEqual('0|99');
		});
		
		it('should should separate integer and fractional parts with separator', function() {
			expect(subject.formatInteger(100)).toEqual('1|00');
			expect(subject.formatInteger(199)).toEqual('1|99');
		});
		
		it('should separate thousands with delimiter', function() {
			expect(subject.formatInteger(100000)).toEqual('1-000|00');
			expect(subject.formatInteger(99988877)).toEqual('999-888|77');
			expect(subject.formatInteger(99988877766655)).toEqual('999-888-777-666|55');
			expect(subject.formatInteger(199988877766655)).toEqual('1-999-888-777-666|55');
		});
		
		it('should raise error if formatting fractional number', function() {
			expect(function() {
				subject.formatInteger(100.2).toThrowError('100.2 is not integer.');
			});
		});
	});
});