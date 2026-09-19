'use strict';
// DOM behaviour checks, not a real browser/WordPress integration test.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
class Element {
  constructor(tag = 'div') { this.tag = tag; this.children = []; this.listeners = {}; this.style = {}; this.value = ''; this.textContent = ''; }
  append(...values) { this.children.push(...values); }
  replaceChildren(...values) { this.children = values; }
  addEventListener(type, callback) { this.listeners[type] = callback; }
  click() { this.listeners.click?.({ preventDefault() {} }); }
  change() { this.listeners.change?.({ preventDefault() {} }); }
}
const elements = {};
for (const id of ['kanz-json', 'kanz-error', 'kanz-sections', 'kanz-updates', 'kanz-all-fields', 'kanz-apply', 'kanz-import', 'kanz-add-banner', 'kanz-add-category', 'kanz-form', 'kanz-export', 'kanz-confirm-updates', 'kanz-category-order']) elements[id] = new Element();
elements['kanz-json'].value = fs.readFileSync(path.join(__dirname, '../../lib/config/config_ar.json'), 'utf8');
const canonicalScript = fs.readFileSync(path.join(__dirname, '../kanz-app-control/admin.js'), 'utf8');
let editorScript = canonicalScript;
if (process.argv.includes('--snippet')) {
  const snippet = fs.readFileSync(path.join(__dirname, '../snippets/kanz-app-control-snippet.php'), 'utf8');
  const match = snippet.match(/return <<<'KANZ_CONTROL_EDITOR_JS'\r?\n([\s\S]*?)\r?\nKANZ_CONTROL_EDITOR_JS;/);
  assert.ok(match, 'Inline script missing');
  editorScript = match[1];
  assert.ok(editorScript.includes(canonicalScript.trim()), 'Snippet editor is out of sync');
}
vm.runInNewContext(editorScript, {
  document: { getElementById: (id) => elements[id], createElement: (tag) => new Element(tag) },
  window: { confirm: () => true }, kanzAdmin: { categories: [{ id: '124', name: 'سبائك ذهب' }, { id: '130', name: 'جنيهات ذهب' }, { id: '430', name: 'سبائك فضة' }], products: [{ id: '101', name: 'سبيكة 10 جرام' }] },
  setTimeout, Blob, URL,
});
const read = () => JSON.parse(elements['kanz-json'].value);
assert.equal(elements['kanz-sections'].children.length, 11);
const descendants = (element) => [element, ...element.children.flatMap((child) => typeof child === 'object' ? descendants(child) : [])];
const firstBannerCard = elements['kanz-sections'].children[1];
const insertBefore = descendants(firstBannerCard).find((item) => item.tag === 'button' && item.textContent === 'إضافة قسم منتجات قبله');
assert.ok(insertBefore);
insertBefore.click();
assert.equal(read().HorizonLayout[1].layout, 'oneAndHalfColumn');
assert.equal(read().HorizonLayout[2].items[0].image, 'https://kanzalsahra.com/wp-content/uploads/2026/03/Frame-375-700x263.png');
assert.equal(elements['kanz-sections'].children.length, 12);
const orderInput = descendants(elements['kanz-category-order']).find((item) => item.tag === 'input' && item.type === 'number');
assert.ok(orderInput);
assert.equal(orderInput.step, '1');
const orderBeforeInvalidEdit = read().TabBar.find((item) => item.layout === 'category').categories.slice();
orderInput.value = '2.5'; orderInput.change();
assert.deepEqual(read().TabBar.find((item) => item.layout === 'category').categories, orderBeforeInvalidEdit);
assert.equal(orderInput.value, '1');
const modified = read(); modified.Setting.MainColor = '#abcdef';
elements['kanz-json'].value = JSON.stringify(modified);
elements['kanz-json'].listeners.input();
elements['kanz-add-banner'].click();
assert.equal(read().HorizonLayout.length, 12); // dirty text is not overwritten
assert.ok(elements['kanz-error'].textContent);
elements['kanz-apply'].click(); elements['kanz-add-banner'].click();
assert.equal(read().HorizonLayout.length, 13);
assert.equal(read().Setting.MainColor, '#abcdef');
const custom = read(); custom.CustomField = { text: 'preserved value' };
elements['kanz-json'].value = JSON.stringify(custom); elements['kanz-apply'].click();
elements['kanz-add-category'].click();
assert.equal(read().CustomField.text, 'preserved value');
assert.equal(read().HorizonLayout.at(-1).layout, 'oneAndHalfColumn');
const forcing = read(); forcing.KanzControl = { updates: { android: { enabled: true, minimumBuild: 23 } } };
elements['kanz-json'].value = JSON.stringify(forcing);
let blocked = false;
elements['kanz-form'].listeners.submit({ preventDefault() { blocked = true; } });
assert.equal(blocked, true);
elements['kanz-confirm-updates'].checked = true; blocked = false;
elements['kanz-form'].listeners.submit({ preventDefault() { blocked = true; } });
assert.equal(blocked, false);
console.log('Editor behaviour checks passed: import rendering, dirty-edit preservation, banner/category creation, unknown fields and update acknowledgement.');
