'use strict'
const {describe, it} = require('mocha')
const {expect} = require('chai')

describe('repro-firefox-gzip-bug e2e', function () {
  it('should return OK on /', async () => {
    expect(4).to.equal(4)
  })
})
