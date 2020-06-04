'use strict'
const {describe = global.describe, it = global.it} = require('mocha')
const {expect} = require('chai')

describe('repro-firefox-gzip-bug', function () {
  it('should do amazing stuff', async () => {
    expect(4).to.equal(4)
  })
})
