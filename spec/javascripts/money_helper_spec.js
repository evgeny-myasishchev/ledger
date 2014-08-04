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
			expect(subject.formatInteger(1)).toEqual('0|01');
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
				subject.formatInteger(100.2);
			}).toThrowError('100.2 is not integer.');
		});
	});
	
	describe('parse', function() {
		it('should raise error if parsing something different than string or number', function() {
			expect(function() {
				subject.parse({});
			}).toThrowError("Can not parse. String or number is expected. Got object.")
		});

		describe('string', function() {
			it('should return an integer removing separator', function() {
				expect(subject.parse('10|01')).toEqual(1001);
			});
			it('should return an integer removing separator and delimiter', function() {
				expect(subject.parse('9-888-777-666|55')).toEqual(988877766655);
			});
			it('should add decimal part', function() {
				expect(subject.parse('100')).toEqual(10000);
			});
			it('should raise error if fractional part is longer than two symbols', function() {
				expect(function() {
					subject.parse('100|223');
				}).toThrowError("Can not parse '100|223'. Fractional part is longer than two dights.")
			});
			it('should raise error if no fractional part', function() {
				expect(function() {
					subject.parse('100|');
				}).toThrowError("Can not parse '100|'. Fractional part is missing.")
			});
			it('should raise error if empty string', function() {
				expect(function() {
					subject.parse('');
				}).toThrowError("Can not parse ''. Invalid money string.")
			});
			it('should raise error if several decimal separators', function() {
				expect(function() {
					subject.parse('100|200|300');
				}).toThrowError("Can not parse '100|200|300'. Invalid money string.")
			});
		});
		describe('integer', function() {
			it('should return it as is', function() {
				expect(subject.parse(10022)).toEqual(10022);
			});
		});
		describe('fractional', function() {
			it('should raise error', function() {
				expect(function() {
					subject.parse(100.2);
				}).toThrowError('Can not parse 100.2. Parsing fractional numbers is not supported.');
			});
		});
	});
});