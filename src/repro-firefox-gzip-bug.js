'use strict'
const {Builder} = require('selenium-webdriver')
// require('geckodriver')

async function main() {
  const driver = await new Builder()
    .forBrowser('firefox')
    // uncomment for accessing Selenium docker
    // .usingServer('http://localhost:4444/wd/hub')
    // use this for access the Applitools Docker image Browser
    .usingServer('http://localhost:4444/')
    .build()
  try {
    await driver.get('https://www.amazon.com')
    const version = await driver.executeScript(() => window.navigator.userAgent)
    const html = await driver.executeScript(() => document.querySelector('html').outerHTML.slice(0, 1000))
    console.log(`*********** `, {html: html.slice(0, 1000), version}) //@@@GIL
  } finally {
    await driver.quit()
  }
}

main().catch(console.error)

module.exports = main
