assert = require('assert')
subj = require('../src/fhirv.coffee')


describe "validate", ->
  it "arity", ->
    res = subj.validate_arity({max: '*'}, ['path'], 'value')
    assert.deepEqual(res, [{path: 'path', type: 'expected-array', but: 'value'}])

    res = subj.validate_arity({min: 1, max: '*'}, ['path'], [])
    assert.deepEqual(res, [{path: 'path', type: 'arity-error', expected: 'min = 1', got: 'min = 0'}])

    res = subj.validate_arity({min: 2, max: '*'}, ['path'], ['one'])
    assert.deepEqual(res, [{path: 'path', type: 'arity-error', expected: 'min = 2', got: 'min = 1'}])

    res = subj.validate_arity({min: 1}, ['path'], null)
    assert.deepEqual(res, [{path: 'path', type: 'required'}])

    res = subj.validate_arity({max: '2'}, ['path'], ['a', 'b', 'c'])
    assert.deepEqual(res, [{path: 'path', type: 'arity-error', expected: 'max = 2', got: 'max = 3'}])
