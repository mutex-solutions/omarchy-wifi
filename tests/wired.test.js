const assert = require("assert")
const fs = require("fs"), path = require("path"), vm = require("vm")
function load(file) {
  const src = fs.readFileSync(file, "utf8").replace(/^\.pragma library\n/, "")
  const model = {}; vm.runInNewContext(src, model); return model
}
const Link = load(path.join(__dirname, "../LinkModel.js"))
const stockPath = "/usr/share/omarchy/shell/plugins/panels/network/Model.js"
const Stock = fs.existsSync(stockPath) ? load(stockPath) : null
let count = 0
function t(name, fn) { fn(); count++ }

t("wired wins when both links are connected", () => {
  assert.equal(Link.linkKind(true, true, true), "ethernet")
  assert.equal(Link.linkKind(true, false, false), "ethernet")
})
t("Wi-Fi works alone and keeps the device-level OWE fallback", () => {
  assert.equal(Link.linkKind(false, true, true), "wifi")
  assert.equal(Link.linkKind(false, false, true), "wifi")
  assert.equal(Link.linkKind(false, false, false), "disconnected")
})
if (Stock) t("wired speed and icons use Omarchy's formatters", () => {
  assert.equal(Stock.formatHeaderSpeed("1000"), "1gbit")
  assert.equal(Stock.formatHeaderSpeed("2500"), "2.5gbit")
  assert.equal(Stock.formatHeaderSpeed("100"), "100mbit")
  assert.equal(Stock.connectionIcon("ethernet", 0, "full"), "󰈀")
  assert.equal(Stock.connectionIcon("ethernet", 0, "portal"), "󰈂")
})
else console.log("Omarchy formatter test skipped: stock model not installed")
console.log("wired link model ok: " + count + " tests")
