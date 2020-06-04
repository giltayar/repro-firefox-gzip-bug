'use strict'
const {Builder} = require('selenium-webdriver')

async function main() {
  const driver = await new Builder()
    .forBrowser('firefox')
    .usingServer('http://localhost:4444/wd/hub')
    .build()
  try {
    await driver.get('https://www.amazon.com')
    const version = await driver.executeScript(() => window.navigator.userAgent)
    const html = await driver.executeScript(() => document.querySelector('html').outerHTML)
    console.log(`*********** `, {html: html.slice(0, 1000), version}) //@@@GIL
  } finally {
    await driver.quit()
  }
}

main().catch(console.error)

module.exports = main
