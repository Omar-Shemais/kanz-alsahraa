<?php
/**
 * Kanz App Control — standalone PHP snippet, version 0.3.0.
 * In Code Snippets paste WITHOUT this opening <?php line.
 * Run everywhere: both admin-post handlers and the public config REST route
 * are required. Do not activate together with the equivalent Kanz plugin.
 * Function names are versioned so Code Snippets can safely validate this
 * replacement while an older revision is still active in the same request.
 * Firebase credentials are NOT embedded here. Deployment is not verified.
 */
if (!defined('ABSPATH')) { return; }
if (!function_exists('kanz_v3_config_validate')) {
function kanz_v3_snippet_admin_js() {
    return <<<'KANZ_CONTROL_EDITOR_JS'
(() => {
  const start = () => {
/* global wp, kanzAdmin */
(() => {
  'use strict';
  const json = document.getElementById('kanz-json');
  if (!json) return;
  const container = document.getElementById('kanz-sections');
  const error = document.getElementById('kanz-error');
  let config;
  let textDirty = false;
  const expandedFields = new Set();
  const message = (value) => { error.textContent = value; };
  function validate(value) {
    if (!value || !Array.isArray(value.HorizonLayout) || !Array.isArray(value.TabBar) || !value.TabBar.length || !value.Setting || Array.isArray(value.Setting) || typeof value.Setting !== 'object') {
      throw new Error('الملف يحتاج HorizonLayout وTabBar وSetting صحيحة.');
    }
    return value;
  }
  function sync() { json.value = JSON.stringify(config, null, 2); textDirty = false; }
  function apply() {
    try { config = validate(JSON.parse(json.value)); textDirty = false; render(); message(''); }
    catch (_) { message('JSON غير صالح أو تنقصه إعدادات التطبيق. لم يتغير المحرر.'); }
  }
  function change(action) {
    if (textDirty) { message('طبّق تعديلات JSON على المحرر أولاً؛ لن يتم استبدال نصك.'); return; }
    if (!config) { message('استورد ملف إعدادات التطبيق أولاً.'); return; }
    try { action(); sync(); render(); message(''); }
    catch (failure) { message(failure.message || 'راجع القيمة المدخلة.'); }
  }
  function button(label, action, parent) {
    const item = document.createElement('button');
    item.type = 'button'; item.className = 'button'; item.textContent = label;
    item.style.margin = '4px'; item.addEventListener('click', action); parent.append(item);
  }
  function field(label, value, action, parent) {
    const wrapper = document.createElement('label'); wrapper.textContent = `${label}: `;
    wrapper.style.display = 'block'; wrapper.style.margin = '8px';
    const input = document.createElement('input'); input.type = 'text'; input.value = value ?? '';
    input.addEventListener('change', () => change(() => action(input.value)));
    wrapper.append(input); parent.append(wrapper);
  }
  function media(action) {
    if (!window.wp || !wp.media) { message('تعذر فتح مكتبة الوسائط.'); return; }
    const picker = wp.media({ title: 'اختر صورة البانر', multiple: false, library: { type: 'image' } });
    picker.on('select', () => {
      const item = picker.state().get('selection').first().toJSON();
      change(() => action(item.url));
    }); picker.open();
  }
  function categoryField(label, value, action, parent) {
    const categories = typeof kanzAdmin !== 'undefined' ? kanzAdmin.categories : [];
    if (!categories || !categories.length) { field(label, value, action, parent); return; }
    const wrapper = document.createElement('label'); wrapper.textContent = `${label}: `;
    wrapper.style.cssText = 'display:block;margin:8px';
    const filterInput = document.createElement('input');
    filterInput.type = 'search'; filterInput.placeholder = '🔍 تصفية التصنيفات بالاسم...';
    filterInput.style.cssText = 'display:block;margin:4px 0;width:100%;max-width:320px;padding:4px 8px;font-size:13px;border:1px solid #ccc;border-radius:4px';
    const select = document.createElement('select');
    select.style.cssText = 'display:block;width:100%;max-width:320px';
    const options = [{ id: '', name: 'بدون تصنيف محدد' }, ...categories];
    if (value != null && String(value) && !options.some((item) => item.id === String(value))) {
      options.push({ id: String(value), name: `التصنيف الحالي #${value} (غير موجود في القائمة)` });
    }
    const populate = (query = '') => {
      select.replaceChildren();
      const lower = query.trim().toLowerCase();
      options.forEach((item) => {
        if (!lower || item.name.toLowerCase().includes(lower) || item.id === String(value)) {
          const option = document.createElement('option'); option.value = item.id;
          option.textContent = item.id ? `${item.name} — #${item.id}` : item.name;
          select.append(option);
        }
      });
      select.value = String(value ?? '');
    };
    filterInput.addEventListener('input', () => populate(filterInput.value));
    select.addEventListener('change', () => change(() => { value = select.value; action(select.value); }));
    populate('');
    wrapper.append(filterInput, select); parent.append(wrapper);
  }
  function newProductSection() {
    return {
      layout: 'oneAndHalfColumn',
      name: 'قسم منتجات جديد',
      category: '',
      limit: 12,
      rows: 1,
      productListItemHeight: 420,
      imageWidth: 260,
      imageRatio: 0.55,
      showCartButton: true,
      cardDesign: 'card',
      titleLine: 1,
      borderColor: '#B18729',
      borderWidth: 1,
      priceColor: '#B18729',
      borderRadius: 15,
      isSnapping: true,
      enableAutoSliding: false,
      enableBackground: true,
    };
  }
  function render() {
    container.replaceChildren();
    if (!config) return;
    renderUpdates();
    renderAppearance();
    renderAllFields();
    renderCategoryOrder();
    config.HorizonLayout.forEach((section, index) => {
      const card = document.createElement('div');
      card.style.cssText = 'border:1px solid #ccc;padding:12px;margin:12px 0;background:white';
      const title = document.createElement('h3'); title.textContent = `${index + 1}. ${section.name || section.layout}`; card.append(title);
      button('↑', () => change(() => { if (index > 0) [config.HorizonLayout[index - 1], config.HorizonLayout[index]] = [section, config.HorizonLayout[index - 1]]; }), card);
      button('↓', () => change(() => { if (index + 1 < config.HorizonLayout.length) [config.HorizonLayout[index + 1], config.HorizonLayout[index]] = [section, config.HorizonLayout[index + 1]]; }), card);
      button('إضافة قسم منتجات قبله', () => change(() => config.HorizonLayout.splice(index, 0, newProductSection())), card);
      button('حذف القسم', () => { if (window.confirm('حذف القسم من المسودة؟')) change(() => config.HorizonLayout.splice(index, 1)); }, card);
      field('الاسم', section.name, (value) => { section.name = value; }, card);
      if (!['logo', 'bannerImage', 'luxurySaleBanner'].includes(section.layout)) {
        categoryField('تصنيف المنتجات', section.category, (value) => { section.category = value; }, card);
        field('عدد المنتجات', section.limit ?? 12, (value) => {
          const count = Number(value);
          if (!Number.isInteger(count) || count < 1 || count > 100) throw new Error('عدد المنتجات من 1 إلى 100.');
          section.limit = count;
        }, card);
        const sort = document.createElement('select');
        [['', 'ترتيب المتجر'], ['popularity', 'الأكثر مبيعاً'], ['date', 'الأحدث'], ['rating', 'الأعلى تقييماً'], ['price', 'حسب السعر']].forEach(([key, label]) => {
          const option = document.createElement('option'); option.value = key; option.textContent = label; sort.append(option);
        });
        sort.value = section.orderby || '';
        sort.addEventListener('change', () => change(() => {
          if (sort.value) { section.orderby = sort.value; section.order = 'desc'; }
          else { delete section.orderby; delete section.order; }
        })); card.append(sort);
      }
      if (['bannerImage', 'luxurySaleBanner'].includes(section.layout)) {
        (section.items || []).forEach((item, itemIndex) => {
          const row = document.createElement('div');
          row.style.cssText = 'border:1px solid #ddd;border-radius:6px;padding:12px;margin:8px 0;background:#fafafa';
          const header = document.createElement('div');
          header.style.cssText = 'display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;border-bottom:1px solid #eee;padding-bottom:6px';
          const itemTitle = document.createElement('strong');
          itemTitle.textContent = `العنصر ${itemIndex + 1}`;
          header.append(itemTitle);
          const controls = document.createElement('div');
          button('↑', () => change(() => { if (itemIndex > 0) [section.items[itemIndex - 1], section.items[itemIndex]] = [item, section.items[itemIndex - 1]]; }), controls);
          button('↓', () => change(() => { if (itemIndex + 1 < section.items.length) [section.items[itemIndex + 1], section.items[itemIndex]] = [item, section.items[itemIndex + 1]]; }), controls);
          button('حذف العنصر', () => change(() => section.items.splice(itemIndex, 1)), controls);
          header.append(controls);
          row.append(header);
          field('رابط الصورة', item.image, (value) => { item.image = value; }, row);
          button('اختيار الصورة من الوسائط', () => media((url) => { item.image = url; }), row);
          destinationField(item, row);
          card.append(row);
        });
        button('إضافة عنصر جديد', () => change(() => { (section.items ||= []).push({ image: '', category: '', radius: 9 }); }), card);
      }
      container.append(card);
    });
  }
  function selectField(label, options, value, action, parent) {
    const wrapper = document.createElement('label'); wrapper.textContent = `${label}: `;
    const select = document.createElement('select');
    options.forEach(([key, text]) => { const option = document.createElement('option'); option.value = key; option.textContent = text; select.append(option); });
    select.value = value;
    select.addEventListener('change', () => change(() => action(select.value)));
    wrapper.append(select); parent.append(wrapper);
  }
  function destinationField(item, parent) {
    const keys = ['category', 'product', 'url', 'urlLaunch', 'screen', 'tab', 'tabNumber', 'tab_number', 'blog', 'blog_category', 'tag', 'coupon', 'vendor'];
    const current = item.kanzDestinationType || (item.product ? 'product' : item.category ? 'category' : item.urlLaunch ? 'urlLaunch' : item.tab_number ? 'tab_number' : item.url ? 'legacy' : keys.some((key) => item[key]) ? 'legacy' : 'none');
    const clear = () => keys.forEach((key) => delete item[key]);
    selectField('وجهة الضغط', [['none', 'بدون انتقال'], ['category', 'تصنيف'], ['product', 'منتج'], ['tab_number', 'صفحة رئيسية بالتطبيق'], ['urlLaunch', 'رابط HTTPS'], ['legacy', 'وجهة حالية متقدمة — الحفاظ عليها']], current, (value) => {
      if (value === 'legacy') return;
      clear();
      if (value === 'category' || value === 'product') item[value] = '';
      if (value === 'tab_number') item.tab_number = '1';
      if (value === 'urlLaunch') item.urlLaunch = 'https://kanzalsahra.com/';
      item.kanzDestinationType = value;
    }, parent);
    const type = item.kanzDestinationType || current;
    if (type === 'category') categoryField('التصنيف عند الضغط', item.category, (value) => { clear(); item.category = value; }, parent);
    if (type === 'product') {
      const products = (kanzAdmin.products || []).map((product) => [String(product.id), product.name]);
      if (item.product && !products.some(([id]) => id === String(item.product))) products.push([String(item.product), `المنتج الحالي #${item.product}`]);
      const productOptions = [['', 'اختر المنتج'], ...products];
      const wrapper = document.createElement('label'); wrapper.textContent = 'المنتج عند الضغط: ';
      wrapper.style.cssText = 'display:block;margin:8px';
      const filterInput = document.createElement('input');
      filterInput.type = 'search'; filterInput.placeholder = '🔍 تصفية المنتجات بالاسم...';
      filterInput.style.cssText = 'display:block;margin:4px 0;width:100%;max-width:320px;padding:4px 8px;font-size:13px;border:1px solid #ccc;border-radius:4px';
      const select = document.createElement('select');
      select.style.cssText = 'display:block;width:100%;max-width:320px';
      const populate = (query = '') => {
        select.replaceChildren();
        const lower = query.trim().toLowerCase();
        productOptions.forEach(([id, name]) => {
          if (!lower || name.toLowerCase().includes(lower) || id === String(item.product)) {
            const option = document.createElement('option'); option.value = id; option.textContent = name; select.append(option);
          }
        });
        select.value = String(item.product || '');
      };
      filterInput.addEventListener('input', () => populate(filterInput.value));
      select.addEventListener('change', () => change(() => { clear(); item.product = select.value; }));
      populate('');
      wrapper.append(filterInput, select); parent.append(wrapper);
    }
    if (type === 'tab_number') selectField('الصفحة', config.TabBar.map((tab, index) => [String(index + 1), ({ home: 'الرئيسية', category: 'التصنيفات', cart: 'السلة', profile: 'الحساب' })[tab.layout] || tab.layout]), String(item.tab_number || '1'), (value) => { clear(); item.tab_number = value; }, parent);
    if (type === 'urlLaunch') field('الرابط الخارجي', item.urlLaunch, (value) => {
      const uri = new URL(value);
      if (uri.protocol !== 'https:' || uri.username || uri.password) throw new Error('استخدم رابط HTTPS دون بيانات دخول.');
      clear(); item.urlLaunch = uri.href;
    }, parent);
  }
  function renderCategoryOrder() {
    const panel = document.getElementById('kanz-category-order'); if (!panel) return;
    panel.replaceChildren();
    const tab = config.TabBar.find((item) => item.layout === 'category'); if (!tab) return;
    const available = kanzAdmin.categories || [];
    const activeRoots = available.filter((item) => !item.parent && item.count > 0);
    const otherRoots = available.filter((item) => !item.parent && !(item.count > 0));
    const activeSubs = available.filter((item) => !!item.parent && item.count > 0);
    const otherSubs = available.filter((item) => !!item.parent && !(item.count > 0));
    const defaultOrder = [...activeRoots, ...otherRoots, ...activeSubs, ...otherSubs].map((item) => String(item.id));
    const ids = [...new Set([...(tab.categories || []).map(String), ...defaultOrder])];
    if (!ids.length) {
      const empty = document.createElement('p');
      empty.textContent = 'لا توجد تصنيفات متاحة للترتيب.';
      panel.append(empty);
      return;
    }
    if (!tab.categories || !tab.categories.length) {
      tab.categories = ids;
      sync();
    }

    const controls = document.createElement('div');
    controls.style.cssText = 'display:flex;flex-wrap:wrap;align-items:center;gap:10px;margin:8px 0 14px 0;max-width:700px';

    const filterInput = document.createElement('input');
    filterInput.type = 'search'; filterInput.placeholder = '🔍 ابحث في التصنيفات لترتيبها...';
    filterInput.style.cssText = 'flex:1;min-width:200px;padding:8px 12px;border:1px solid #ccd0d4;border-radius:6px;font-size:14px';
    controls.append(filterInput);

    let viewMode = 'all';

    const filterGroup = document.createElement('div');
    filterGroup.style.cssText = 'display:flex;gap:4px';

    const btnAll = document.createElement('button');
    btnAll.type = 'button'; btnAll.className = 'button button-primary';
    btnAll.textContent = 'الكل';
    filterGroup.append(btnAll);

    const btnRoots = document.createElement('button');
    btnRoots.type = 'button'; btnRoots.className = 'button';
    btnRoots.textContent = '🟢 الأقسام الرئيسية';
    filterGroup.append(btnRoots);

    const btnActive = document.createElement('button');
    btnActive.type = 'button'; btnActive.className = 'button';
    btnActive.textContent = '📦 بها منتجات فقط';
    btnActive.title = 'عرض الأقسام التي تحتوي على منتجات وتظهر فعلياً في التطبيق';
    filterGroup.append(btnActive);

    const btnSubs = document.createElement('button');
    btnSubs.type = 'button'; btnSubs.className = 'button';
    btnSubs.textContent = '↳ الفرعية';
    filterGroup.append(btnSubs);

    controls.append(filterGroup);

    const btnPrioritizeActive = document.createElement('button');
    btnPrioritizeActive.type = 'button'; btnPrioritizeActive.className = 'button';
    btnPrioritizeActive.textContent = '⚡ ترتيب النشطة أولاً';
    btnPrioritizeActive.title = 'وضع الأقسام الرئيسية التي تحتوي على منتجات وتظهر في التطبيق أولاً';
    controls.append(btnPrioritizeActive);

    const btnPrioritizeRoots = document.createElement('button');
    btnPrioritizeRoots.type = 'button'; btnPrioritizeRoots.className = 'button';
    btnPrioritizeRoots.textContent = '🔝 ترتيب الرئيسية أولاً';
    btnPrioritizeRoots.title = 'وضع جميع الأقسام الرئيسية في مقدمة القائمة';
    controls.append(btnPrioritizeRoots);

    panel.append(controls);

    const listContainer = document.createElement('div');
    panel.append(listContainer);

    let dragSrcIndex = null;

    const updateFilterButtons = () => {
      btnAll.className = viewMode === 'all' ? 'button button-primary' : 'button';
      btnRoots.className = viewMode === 'root' ? 'button button-primary' : 'button';
      btnActive.className = viewMode === 'active' ? 'button button-primary' : 'button';
      btnSubs.className = viewMode === 'sub' ? 'button button-primary' : 'button';
    };

    btnAll.addEventListener('click', () => { viewMode = 'all'; updateFilterButtons(); renderList(filterInput.value); });
    btnRoots.addEventListener('click', () => { viewMode = 'root'; updateFilterButtons(); renderList(filterInput.value); });
    btnActive.addEventListener('click', () => { viewMode = 'active'; updateFilterButtons(); renderList(filterInput.value); });
    btnSubs.addEventListener('click', () => { viewMode = 'sub'; updateFilterButtons(); renderList(filterInput.value); });

    btnPrioritizeActive.addEventListener('click', () => {
      change(() => {
        const activeRootSet = new Set(available.filter((item) => !item.parent && item.count > 0).map((item) => String(item.id)));
        const otherRootSet = new Set(available.filter((item) => !item.parent && !(item.count > 0)).map((item) => String(item.id)));
        const sortedActiveRoots = ids.filter((id) => activeRootSet.has(id));
        const sortedOtherRoots = ids.filter((id) => otherRootSet.has(id));
        const sortedSubs = ids.filter((id) => !activeRootSet.has(id) && !otherRootSet.has(id));
        ids.length = 0;
        ids.push(...sortedActiveRoots, ...sortedOtherRoots, ...sortedSubs);
        tab.categories = ids;
      });
    });

    btnPrioritizeRoots.addEventListener('click', () => {
      change(() => {
        const rootSet = new Set(available.filter((item) => !item.parent).map((item) => String(item.id)));
        const sortedRoots = ids.filter((id) => rootSet.has(id));
        const sortedSubs = ids.filter((id) => !rootSet.has(id));
        ids.length = 0;
        ids.push(...sortedRoots, ...sortedSubs);
        tab.categories = ids;
      });
    });

    const renderList = (filter = '') => {
      listContainer.replaceChildren();
      const lower = filter.trim().toLowerCase();
      ids.forEach((id, index) => {
        const cat = available.find((item) => String(item.id) === id);
        const catName = cat?.name || `تصنيف #${id}`;
        const isRoot = !cat || !cat.parent;

        if (viewMode === 'root' && !isRoot) return;
        if (viewMode === 'sub' && isRoot) return;
        const count = typeof cat?.count === 'number' ? cat.count : null;
        if (viewMode === 'active' && (count === null || count <= 0)) return;
        if (lower && !catName.toLowerCase().includes(lower) && !id.includes(lower)) return;

        const row = document.createElement('div');
        row.style.cssText = 'display:flex;align-items:center;justify-content:space-between;padding:8px 12px;margin:6px 0;background:#f8f9fa;border:1px solid #ddd;border-radius:6px;max-width:650px;cursor:grab';
        row.draggable = true;

        row.addEventListener('dragstart', (e) => {
          dragSrcIndex = index;
          if (e.dataTransfer) e.dataTransfer.effectAllowed = 'move';
        });
        row.addEventListener('dragover', (e) => {
          if (e.preventDefault) e.preventDefault();
          row.style.background = '#e3f2fd';
        });
        row.addEventListener('dragleave', () => {
          row.style.background = '#f8f9fa';
        });
        row.addEventListener('drop', (e) => {
          if (e.preventDefault) e.preventDefault();
          row.style.background = '#f8f9fa';
          if (dragSrcIndex !== null && dragSrcIndex !== index) {
            change(() => {
              const item = ids.splice(dragSrcIndex, 1)[0];
              ids.splice(index, 0, item);
              tab.categories = ids;
            });
          }
        });

        const left = document.createElement('div');
        left.style.cssText = 'display:flex;align-items:center;flex-wrap:wrap;gap:6px';

        const dragHandle = document.createElement('span');
        dragHandle.textContent = '☰ ';
        dragHandle.style.cssText = 'cursor:grab;margin-left:6px;color:#888;font-size:16px';
        left.append(dragHandle);

        const posInput = document.createElement('input');
        posInput.type = 'number';
        posInput.min = '1';
        posInput.step = '1';
        posInput.max = String(ids.length);
        posInput.value = String(index + 1);
        posInput.title = 'أدخل رقم الترتيب واضغط Enter';
        posInput.style.cssText = 'width:52px;text-align:center;font-weight:bold;margin-left:6px;padding:2px 4px';
        posInput.addEventListener('change', () => {
          const targetPos = Number(posInput.value);
          if (Number.isInteger(targetPos) && targetPos >= 1 && targetPos <= ids.length && targetPos - 1 !== index) {
            change(() => {
              const item = ids.splice(index, 1)[0];
              ids.splice(targetPos - 1, 0, item);
              tab.categories = ids;
            });
          } else {
            posInput.value = String(index + 1);
          }
        });
        left.append(posInput);

        const label = document.createElement('span');
        label.textContent = catName;
        label.style.fontWeight = 'bold';
        left.append(label);

        const badge = document.createElement('span');
        if (isRoot) {
          badge.textContent = '🟢 قسم رئيسي';
          badge.style.cssText = 'background:#e8f5e9;color:#2e7d32;font-size:11px;font-weight:bold;padding:2px 6px;border-radius:4px;margin-inline:4px';
        } else {
          const parentObj = available.find((c) => String(c.id) === String(cat.parent));
          const parentName = parentObj?.name || `#${cat.parent}`;
          badge.textContent = `↳ فرعي من: ${parentName}`;
          badge.style.cssText = 'background:#e3f2fd;color:#1565c0;font-size:11px;padding:2px 6px;border-radius:4px;margin-inline:4px';
        }
        left.append(badge);

        const countBadge = document.createElement('span');
        if (count !== null && count > 0) {
          countBadge.textContent = `📦 ${count} منتج`;
          countBadge.style.cssText = 'background:#e8f5e9;color:#2e7d32;font-size:11px;font-weight:bold;padding:2px 6px;border-radius:4px;margin-inline:4px';
        } else if (count === 0) {
          countBadge.textContent = '⚠️ 0 منتج (غير ظاهر بالتطبيق)';
          countBadge.style.cssText = 'background:#fff3e0;color:#c67d00;font-size:11px;padding:2px 6px;border-radius:4px;margin-inline:4px';
        }
        left.append(countBadge);

        row.append(left);

        const actions = document.createElement('div');
        actions.style.cssText = 'display:flex;gap:2px';
        const move = (offset) => {
          if (index + offset < 0 || index + offset >= ids.length) return;
          [ids[index], ids[index + offset]] = [ids[index + offset], ids[index]];
          tab.categories = ids;
        };
        const moveTo = (target) => {
          if (target === index) return;
          const item = ids.splice(index, 1)[0];
          ids.splice(target, 0, item);
          tab.categories = ids;
        };

        button('⤒', () => change(() => moveTo(0)), actions);
        button('↑', () => change(() => move(-1)), actions);
        button('↓', () => change(() => move(1)), actions);
        button('⤓', () => change(() => moveTo(ids.length - 1)), actions);
        row.append(actions);

        listContainer.append(row);
      });
    };

    filterInput.addEventListener('input', () => renderList(filterInput.value));
    renderList('');
  }
  function renderUpdates() {
    const updates = document.getElementById('kanz-updates'); if (!updates) return;
    updates.replaceChildren();
    ['android', 'ios'].forEach((platform) => {
      const setting = config.KanzControl?.updates?.[platform] || { enabled: false, minimumBuild: 0 };
      const card = document.createElement('div');
      const title = document.createElement('h3'); title.textContent = platform === 'android' ? 'Android' : 'iPhone'; card.append(title);
      const set = (key, value) => {
        config.KanzControl ||= {}; config.KanzControl.updates ||= {};
        config.KanzControl.updates[platform] = { ...setting, [key]: value };
      };
      field('الحد الأدنى لرقم البناء', setting.minimumBuild, (value) => {
        const minimum = Number(value);
        if (!Number.isInteger(minimum) || minimum < 0 || minimum > 2147483647) throw new Error('أدخل رقم بناء صحيحاً.');
        set('minimumBuild', minimum);
      }, card);
      const label = document.createElement('label');
      const checkbox = document.createElement('input'); checkbox.type = 'checkbox'; checkbox.checked = setting.enabled === true;
      checkbox.addEventListener('change', () => change(() => {
        if (checkbox.checked && (setting.minimumBuild < 1 || !window.confirm('هل الإصدار المطلوب متاح فعلياً في المتجر؟ إجبار إصدار غير متاح يمنع العملاء من استخدام التطبيق.'))) return;
        set('enabled', checkbox.checked);
      })); label.append(checkbox, 'إجبار تحديث الإصدارات الأقدم'); card.append(label); updates.append(card);
    });
  }
  function renderAppearance() {
    const panel = document.getElementById('kanz-appearance'); if (!panel) return;
    panel.replaceChildren();
    const note = document.createElement('p');
    note.textContent = 'يطبّق هذا الاختيار على التثبيتات التي لم يغيّر أصحابها المظهر يدوياً. اختيار المستخدم داخل التطبيق يبقى محفوظاً.';
    panel.append(note);
    selectField(
      'المظهر الافتراضي',
      [['dark', 'داكن'], ['light', 'فاتح']],
      config.Setting.DefaultTheme === 'light' ? 'light' : 'dark',
      (value) => { config.Setting.DefaultTheme = value; },
      panel,
    );
  }
  function renderAllFields() {
    const root = document.getElementById('kanz-all-fields'); if (!root) return;
    root.replaceChildren();
    const labels = {
      Setting: 'إعدادات المظهر', HorizonLayout: 'أقسام الصفحة الرئيسية', TabBar: 'شريط التنقل',
      MainColor: 'اللون الرئيسي', FontFamily: 'خط النصوص', FontHeader: 'خط العناوين',
      name: 'الاسم', image: 'رابط الصورة', category: 'رقم التصنيف', title: 'العنوان',
      items: 'العناصر', itemsWeb: 'عناصر نسخة الويب', layout: 'نوع العرض', limit: 'عدد المنتجات',
      showSearch: 'إظهار البحث', showLogo: 'إظهار الشعار', showMenu: 'إظهار القائمة',
      autoPlay: 'تشغيل البانرات تلقائياً', height: 'الارتفاع', radius: 'استدارة الزوايا',
      KanzControl: 'التحكم في التطبيق', updates: 'التحديثات', minimumBuild: 'الحد الأدنى لرقم البناء',
      enabled: 'مفعّل', DefaultTheme: 'المظهر الافتراضي', PrivacyPoliciesPageUrlOrId: 'رابط سياسة الخصوصية',
    };
    function walk(parent, key, value, target, path) {
      const label = labels[key] || String(key);
      if (value !== null && typeof value === 'object') {
        const details = document.createElement('details'); details.open = expandedFields.has(path);
        const summary = document.createElement('summary'); summary.textContent = label; details.append(summary);
        details.addEventListener('toggle', () => {
          if (details.open) expandedFields.add(path); else expandedFields.delete(path);
        });
        Object.entries(value).forEach(([childKey, child]) => walk(value, childKey, child, details, `${path}/${childKey}`));
        target.append(details); return;
      }
      const wrapper = document.createElement('label'); wrapper.style.cssText = 'display:block;margin:8px 18px';
      wrapper.append(`${label}: `);
      const input = document.createElement(typeof value === 'string' && value.length > 100 ? 'textarea' : 'input');
      if (typeof value === 'boolean') { input.type = 'checkbox'; input.checked = value; }
      else if (typeof value === 'number') { input.type = 'number'; input.step = 'any'; input.value = value; }
      else { input.value = value === null ? '' : String(value); }
      input.addEventListener('change', () => change(() => {
        if (typeof value === 'boolean') parent[key] = input.checked;
        else if (typeof value === 'number') {
          if (!input.value.trim() || !Number.isFinite(Number(input.value))) throw new Error('أدخل رقماً صحيحاً.');
          parent[key] = Number(input.value);
        } else if (value === null) {
          throw new Error('القيمة الفارغة null تحتاج تحرير JSON المتقدم لتغيير نوعها.');
        } else parent[key] = input.value;
      }));
      wrapper.append(input); target.append(wrapper);
    }
    Object.entries(config).forEach(([key, value]) => walk(config, key, value, root, key));
  }
  json.addEventListener('input', () => { textDirty = true; });
  document.getElementById('kanz-apply').addEventListener('click', apply);
  document.getElementById('kanz-import').addEventListener('change', async (event) => {
    const file = event.target.files[0]; if (!file) return;
    if (file.size > 1048576) { message('الملف أكبر من 1 ميجابايت.'); return; }
    try {
      const value = validate(JSON.parse(await file.text()));
      if (json.value && !window.confirm('استبدال المسودة بالملف المستورد؟')) return;
      config = value; sync(); render(); message('تم الاستيراد إلى المسودة فقط. راجعها قبل النشر.');
    } catch (_) { message('تعذر قراءة ملف إعدادات صالح.'); }
  });
  document.getElementById('kanz-add-banner').addEventListener('click', () => change(() => config.HorizonLayout.push({ layout: 'bannerImage', design: 'static', items: [] })));
  document.getElementById('kanz-add-category').addEventListener('click', () => change(() => config.HorizonLayout.push(newProductSection())));
  document.getElementById('kanz-form').addEventListener('submit', (event) => {
    try {
      const publishing = validate(JSON.parse(json.value));
      if (Object.values(publishing.KanzControl?.updates || {}).some((item) => item.enabled === true) && !document.getElementById('kanz-confirm-updates')?.checked) {
        event.preventDefault(); message('أكد توفر الإصدار المطلوب في المتجر قبل نشر التحديث الإجباري.'); return;
      }
      if (!window.confirm('نشر هذه الإعدادات للتطبيق؟')) event.preventDefault();
    } catch (_) { event.preventDefault(); message('أصلح JSON قبل النشر.'); }
  });
  document.getElementById('kanz-export')?.addEventListener('click', () => {
    try {
      const value = validate(JSON.parse(json.value));
      const url = URL.createObjectURL(new Blob([JSON.stringify(value, null, 2)], { type: 'application/json' }));
      const link = document.createElement('a'); link.href = url; link.download = 'config_ar.json'; link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } catch (_) { message('صحح الملف قبل تحميله.'); }
  });
  if (json.value) apply();
})();

  };
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start, { once: true });
  } else { start(); }
})();
KANZ_CONTROL_EDITOR_JS;
}
function kanz_v3_destination_data($type, $value = '') {
    if ($type === 'none') { return array(); }
    if (in_array($type, array('category', 'product'), true) && is_string($value) && preg_match('/^[1-9][0-9]{0,9}$/', $value)) {
        return array('kanz_target' => $type, 'kanz_id' => $value);
    }
    if (in_array($type, array('home', 'category_page', 'cart', 'profile'), true)) { return array('kanz_target' => $type); }
    if ($type === 'url' && is_string($value) && strlen($value) <= 2048 && filter_var($value, FILTER_VALIDATE_URL)) {
        $uri = parse_url($value);
        if (!empty($uri['host']) && isset($uri['scheme']) && $uri['scheme'] === 'https' && !isset($uri['user']) && !isset($uri['pass'])) {
            return array('kanz_target' => 'url', 'kanz_url' => $value);
        }
    }
    return new WP_Error('invalid_destination', 'اختر وجهة صحيحة ورقم منتج أو تصنيف صالح، أو رابط HTTPS دون بيانات دخول.');
}

function kanz_v3_destination_options($kind) {
    if ($kind === 'category') {
        if (!taxonomy_exists('product_cat')) { return array(); }
        $terms = get_terms(array('taxonomy' => 'product_cat', 'hide_empty' => false));
        if (is_wp_error($terms)) { return array(); }
        return array_map(function ($term) {
            return array(
                'id' => (string) $term->term_id,
                'name' => $term->name,
                'parent' => (int) $term->parent,
            );
        }, $terms);
    }
    $posts = get_posts(array('post_type' => 'product', 'post_status' => 'publish', 'numberposts' => 500, 'orderby' => 'title', 'order' => 'ASC'));
    return array_map(function ($post) { return array('id' => (string) $post->ID, 'name' => $post->post_title); }, $posts);
}

function kanz_v3_notification_payload($title, $body, $destination = array()) {
    if (!is_string($title) || !is_string($body) || trim($title) === '' || trim($body) === '' ||
        strlen($title) > 240 || strlen($body) > 2400 || strip_tags($title) !== $title || strip_tags($body) !== $body) {
        return new WP_Error('invalid_message', 'أدخل عنواناً ونصاً قصيرين دون HTML.');
    }
    // Marketing only. Never use customer_ID topics for private order data.
    $payload = array('message' => array('topic' => 'all-notifications',
        'notification' => array('title' => trim($title), 'body' => trim($body))));
    if ($destination) {
        $checked = kanz_v3_destination_data(isset($destination['kanz_target']) ? $destination['kanz_target'] : '', isset($destination['kanz_id']) ? $destination['kanz_id'] : (isset($destination['kanz_url']) ? $destination['kanz_url'] : ''));
        if (is_wp_error($checked)) { return $checked; }
        $payload['message']['data'] = $checked;
    }
    return $payload;
}

function kanz_v3_notification_credentials() {
    if (!function_exists('openssl_sign')) {
        return new WP_Error('not_configured', 'الإشعارات غير مربوطة بخدمة Firebase على الخادم.');
    }
    $account = null;
    if (defined('KANZ_FCM_SERVICE_ACCOUNT_FILE')) {
        $path = realpath(KANZ_FCM_SERVICE_ACCOUNT_FILE);
        $root = realpath(isset($_SERVER['DOCUMENT_ROOT']) ? $_SERVER['DOCUMENT_ROOT'] : dirname(ABSPATH));
        // File must be outside the publicly served tree, not a Media upload.
        if ($path && $root && strpos(str_replace('\\', '/', $path), rtrim(str_replace('\\', '/', $root), '/') . '/') !== 0 &&
            is_file($path) && is_readable($path) && filesize($path) <= 65536) {
            $account = json_decode(file_get_contents($path), true);
        }
    }
    if (!$account) {
        $stored = get_option('kanz_fcm_service_account_encrypted', '');
        if (is_string($stored) && trim($stored) !== '') {
            $decoded = kanz_v3_fcm_unseal($stored);
            if (!is_wp_error($decoded)) { $account = json_decode($decoded, true); }
        }
    }
    if (!$account) {
        return new WP_Error('not_configured', 'الإشعارات غير مربوطة بخدمة Firebase. أدخل بيانات مفتاح Firebase في اللوحة أدناه.');
    }
    if (!is_array($account) || empty($account['project_id']) || empty($account['client_email']) || empty($account['private_key']) ||
        !is_string($account['project_id']) || !is_string($account['client_email']) ||
        !preg_match('/^[a-z][a-z0-9-]{4,62}$/', $account['project_id']) ||
        !filter_var($account['client_email'], FILTER_VALIDATE_EMAIL) || !is_string($account['private_key'])) {
        return new WP_Error('invalid_credentials', 'تعذر قراءة إعداد Firebase الخاص. تأكد من صحة ملف JSON.');
    }
    if ($account['project_id'] !== 'kanz-alsahra') { return new WP_Error('wrong_project', 'المفتاح يجب أن يكون لمشروع kanz-alsahra المستخدم في التطبيق.'); }
    return $account;
}

function kanz_v3_fcm_seal($raw) {
    if (!function_exists('openssl_encrypt') || !function_exists('wp_salt')) { return new WP_Error('crypto_missing', 'التشفير غير متاح؛ لم يُحفظ المفتاح.'); }
    $iv = random_bytes(12); $tag = '';
    $key = hash('sha256', wp_salt('auth') . wp_salt('secure_auth'), true);
    $cipher = openssl_encrypt($raw, 'aes-256-gcm', $key, OPENSSL_RAW_DATA, $iv, $tag, 'kanz-fcm-v1');
    if ($cipher === false) { return new WP_Error('crypto_failed', 'تعذر تشفير المفتاح.'); }
    return base64_encode($iv . $tag . $cipher);
}

function kanz_v3_fcm_unseal($stored) {
    if (!function_exists('openssl_decrypt') || !function_exists('wp_salt')) { return new WP_Error('crypto_missing', 'التشفير غير متاح.'); }
    $bytes = base64_decode($stored, true);
    if ($bytes === false || strlen($bytes) < 29) { return new WP_Error('crypto_invalid', 'المفتاح المخزن غير صالح.'); }
    $key = hash('sha256', wp_salt('auth') . wp_salt('secure_auth'), true);
    $raw = openssl_decrypt(substr($bytes, 28), 'aes-256-gcm', $key, OPENSSL_RAW_DATA, substr($bytes, 0, 12), substr($bytes, 12, 16), 'kanz-fcm-v1');
    return $raw === false ? new WP_Error('crypto_invalid', 'تعذر فك المفتاح؛ أعد إعداده بعد تغيير مفاتيح أمان WordPress.') : $raw;
}

function kanz_v3_notification_audience($payload, $audience, $user_id = '') {
    if ($audience === 'broadcast') { return $payload; }
    if ($audience !== 'test_user' || !is_string($user_id) || !preg_match('/^[1-9][0-9]{0,9}$/', $user_id) || !get_userdata((int) $user_id)) {
        return new WP_Error('invalid_test_user', 'حدد رقم حساب WordPress موجود للاختبار.');
    }
    $token = get_user_meta((int) $user_id, 'mstore_device_token', true);
    if (!is_string($token) || !preg_match('/^[A-Za-z0-9_:\-]{40,4096}$/', $token)) {
        return new WP_Error('no_test_device', 'لا يوجد رمز جهاز صالح لهذا الحساب. سجل الدخول في نسخة التطبيق الجديدة أولاً؛ لم تُرسل رسالة عامة.');
    }
    unset($payload['message']['topic']);
    $payload['message']['token'] = $token;
    return $payload;
}

function kanz_v3_notification_send($payload) {
    $account = kanz_v3_notification_credentials();
    if (is_wp_error($account)) { return $account; }
    $encode = function ($value) { return rtrim(strtr(base64_encode($value), '+/', '-_'), '='); };
    $now = time();
    $jwt = $encode(wp_json_encode(array('alg' => 'RS256', 'typ' => 'JWT'))) . '.' .
        $encode(wp_json_encode(array('iss' => $account['client_email'], 'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token', 'iat' => $now, 'exp' => $now + 3600)));
    $signature = '';
    if (!openssl_sign($jwt, $signature, $account['private_key'], OPENSSL_ALGO_SHA256)) {
        return new WP_Error('signing_failed', 'تعذر اعتماد اتصال Firebase.');
    }
    // Fixed Google endpoints; never trust token_uri or URLs from an upload.
    $auth = wp_remote_post('https://oauth2.googleapis.com/token', array('timeout' => 20, 'redirection' => 0, 'sslverify' => true,
        'body' => array('grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => $jwt . '.' . $encode($signature))));
    if (is_wp_error($auth) || wp_remote_retrieve_response_code($auth) !== 200) {
        return new WP_Error('auth_failed', 'تعذر الاتصال بـFirebase. لم يُرسل الإشعار.');
    }
    $token = json_decode(wp_remote_retrieve_body($auth), true);
    if (!is_array($token) || empty($token['access_token']) || !is_string($token['access_token']) || preg_match('/[\r\n]/', $token['access_token'])) {
        return new WP_Error('auth_invalid', 'استجابة Firebase غير صالحة. لم يُرسل الإشعار.');
    }
    $result = wp_remote_post('https://fcm.googleapis.com/v1/projects/' . $account['project_id'] . '/messages:send', array(
        'timeout' => 20, 'redirection' => 0, 'sslverify' => true,
        'headers' => array('Authorization' => 'Bearer ' . $token['access_token'], 'Content-Type' => 'application/json'),
        'body' => wp_json_encode($payload)));
    if (is_wp_error($result)) {
        // A timeout may occur AFTER FCM accepts a message. Never retry silently.
        return new WP_Error('send_uncertain', 'نتيجة الإرسال غير مؤكدة. لا تعاود الإرسال قبل مراجعتها لتجنب التكرار.');
    }
    $accepted = json_decode(wp_remote_retrieve_body($result), true);
    if (wp_remote_retrieve_response_code($result) !== 200 || !is_array($accepted) || empty($accepted['name'])) {
        return new WP_Error('send_rejected', 'لم يؤكد Firebase قبول الرسالة. راجع إعداد المشروع.');
    }
    return true; // Accepted by FCM, not proof of delivery to every device.
}

add_action('admin_post_kanz_send_notification', function () {
    if (!current_user_can('manage_options')) { wp_die('غير مصرح', '', array('response' => 403)); }
    check_admin_referer('kanz_send_notification');
    if (empty($_POST['confirm_broadcast'])) { wp_die('راجع الجمهور وأكد الإرسال أولاً.'); }
    $title = isset($_POST['notification_title']) ? wp_unslash($_POST['notification_title']) : '';
    $body = isset($_POST['notification_body']) ? wp_unslash($_POST['notification_body']) : '';
    $type = isset($_POST['destination_type']) ? wp_unslash($_POST['destination_type']) : 'none';
    $field = $type === 'category' ? 'destination_category' : ($type === 'product' ? 'destination_product' : 'destination_url');
    $value = isset($_POST[$field]) ? wp_unslash($_POST[$field]) : '';
    $destination = kanz_v3_destination_data($type, $value);
    if (is_wp_error($destination)) { wp_die(esc_html($destination->get_error_message())); }
    $payload = kanz_v3_notification_payload($title, $body, $destination);
    if (is_wp_error($payload)) { wp_die(esc_html($payload->get_error_message())); }
    $audience = isset($_POST['notification_audience']) ? wp_unslash($_POST['notification_audience']) : 'test_user';
    $test_user = isset($_POST['notification_test_user']) ? wp_unslash($_POST['notification_test_user']) : '';
    $payload = kanz_v3_notification_audience($payload, $audience, $test_user);
    if (is_wp_error($payload)) { wp_die(esc_html($payload->get_error_message())); }
    $credentials = kanz_v3_notification_credentials();
    if (is_wp_error($credentials)) { wp_die(esc_html($credentials->get_error_message())); }
    $request_id = isset($_POST['request_id']) ? wp_unslash($_POST['request_id']) : '';
    if (!is_string($request_id) || !preg_match('/^[a-f0-9-]{36}$/i', $request_id)) { wp_die('معرف الإرسال غير صالح.'); }
    if (!add_option('kanz_notification_lock', time(), '', false)) { wp_die('هناك إرسال جارٍ. لا تكرر الرسالة.'); }
    $history = get_option('kanz_notification_history', array());
    foreach ($history as $entry) {
        if ($entry['id'] === $request_id || $entry['time'] > time() - 60) {
            delete_option('kanz_notification_lock'); wp_die('تمت معالجة الطلب أو جرت محاولة إرسال خلال الدقيقة الماضية. لا تكرر الرسالة.');
        }
    }
    // Record BEFORE sending. Killed processes do not silently resend on reload.
    $entry = array('id' => $request_id, 'time' => time(), 'status' => 'pending', 'title' => $title, 'audience' => $audience, 'test_user' => $audience === 'test_user' ? (int) $test_user : null);
    array_unshift($history, $entry);
    $history = array_slice($history, 0, 50);
    if (!update_option('kanz_notification_history', $history, false)) {
        delete_option('kanz_notification_lock'); wp_die('تعذر تسجيل الإرسال. لم تُرسل الرسالة.');
    }
    $result = kanz_v3_notification_send($payload);
    $history[0]['status'] = is_wp_error($result) ? $result->get_error_code() : 'accepted';
    update_option('kanz_notification_history', $history, false);
    delete_option('kanz_notification_lock');
    if (is_wp_error($result)) { wp_die(esc_html($result->get_error_message())); }
    wp_safe_redirect(admin_url('admin.php?page=kanz-app-control&notification=accepted'));
    exit;
});

add_action('admin_post_kanz_save_fcm_key', function () {
    if (!current_user_can('manage_options')) { wp_die('غير مصرح', '', array('response' => 403)); }
    check_admin_referer('kanz_save_fcm_key');
    if (!is_ssl() || !function_exists('openssl_pkey_get_private')) { wp_die('يلزم HTTPS ودعم OpenSSL لحفظ المفتاح بأمان.'); }
    if (!empty($_POST['delete_fcm_key'])) {
        delete_option('kanz_fcm_service_account');
        delete_option('kanz_fcm_service_account_encrypted');
        wp_safe_redirect(admin_url('admin.php?page=kanz-app-control&fcm_deleted=1'));
        exit;
    }
    $raw = isset($_POST['fcm_service_account_json']) ? wp_unslash($_POST['fcm_service_account_json']) : '';
    if (!is_string($raw) || strlen($raw) > 65536) { wp_die('الملف كبير جداً أو غير صالح.'); }
    $data = json_decode(trim($raw), true);
    if (!is_array($data) || empty($data['project_id']) || empty($data['client_email']) || empty($data['private_key']) ||
        !is_string($data['project_id']) || !is_string($data['client_email']) ||
        !preg_match('/^[a-z][a-z0-9-]{4,62}$/', $data['project_id']) ||
        !filter_var($data['client_email'], FILTER_VALIDATE_EMAIL) || !is_string($data['private_key'])) {
        wp_die('محتوى JSON غير صالح؛ تأكد من نسخ ملف مفتاح الخدمة الخاص بمشروع Firebase كاملاً.');
    }
    if ($data['project_id'] !== 'kanz-alsahra' || !openssl_pkey_get_private($data['private_key'])) { wp_die('المشروع أو المفتاح الخاص غير صحيح؛ لم يُحفظ المفتاح.'); }
    $sealed = kanz_v3_fcm_seal(wp_json_encode($data));
    if (is_wp_error($sealed)) { wp_die(esc_html($sealed->get_error_message())); }
    if (!update_option('kanz_fcm_service_account_encrypted', $sealed, false)) { wp_die('تعذر حفظ المفتاح المشفر.'); }
    delete_option('kanz_fcm_service_account');
    wp_safe_redirect(admin_url('admin.php?page=kanz-app-control&fcm_saved=1'));
    exit;
});

function kanz_v3_notification_page_section() {
    $credentials = kanz_v3_notification_credentials();
    $ready = !is_wp_error($credentials);
    ?>
    <h2>إشعارات عامة</h2>
    <p>للعروض والأخبار العامة فقط. لا تكتب بيانات طلب أو هاتف أو أي بيانات عميل؛ الجمهور هو المشترك في all-notifications.</p>
    <?php if (isset($_GET['fcm_saved'])) { ?><div class="notice notice-success" style="padding:10px;margin:10px 0"><p style="margin:0;font-weight:bold">تم حفظ المفتاح مشفراً. اختبر حساباً واحداً قبل الإرسال العام؛ الحفظ لا يثبت وصول الإشعارات.</p></div><?php } ?>
    <?php if (isset($_GET['fcm_deleted'])) { ?><div class="notice notice-warning" style="padding:10px;margin:10px 0"><p style="margin:0">تم حذف مفتاح Firebase المربوط.</p></div><?php } ?>
    <?php if ($ready) { ?>
      <div style="background:#e7f5ea;border:1px solid #46b450;border-radius:6px;padding:10px 14px;margin:12px 0">
        <p style="margin:0;font-weight:bold;color:#1d6f2b">✔ خدمة Firebase مربوطة بنجاح بمشروع: <code><?php echo esc_html($credentials['project_id']); ?></code> (<?php echo esc_html($credentials['client_email']); ?>)</p>
      </div>
      <form action="<?php echo esc_url(admin_url('admin-post.php')); ?>" method="post" style="margin-bottom:14px">
        <input type="hidden" name="action" value="kanz_save_fcm_key">
        <input type="hidden" name="delete_fcm_key" value="1">
        <?php wp_nonce_field('kanz_save_fcm_key'); ?>
        <button type="submit" class="button" onclick="return confirm('هل أنت متأكد من حذف مفتاح Firebase المربوط؟');">إلغاء ربط / حذف مفتاح Firebase</button>
      </form>
    <?php } else { ?>
      <div style="background:#fff8e5;border:1px solid #f0b849;border-radius:6px;padding:12px 16px;margin:14px 0">
        <h3 style="margin-top:0">ربط خدمة إشعارات Firebase من اللوحة مباشرة (دون الحاجة لـ cPanel أو FTP)</h3>
        <p>1. من Firebase Console افتح مشروع <code>kanz-alsahra</code> ثم توجه إلى <strong>Project settings &gt; Service accounts</strong> واضغط <strong>Generate new private key</strong>.</p>
        <p>2. اختر ملف الخدمة في هذه اللوحة عبر HTTPS فقط. لا ترسله للمحادثة أو ترفعه للوسائط أو MStore. سيُحفظ مشفراً في قاعدة البيانات باستخدام مفاتيح أمان WordPress؛ اختراق الموقع أو الوصول إلى قاعدة البيانات ومفاتيح الأمان معاً قد يكشفه. تغيير مفاتيح WordPress يتطلب إعادة إدخاله، ونسخة قاعدة البيانات وحدها لا تكفي لاسترجاعه.</p>
        <form action="<?php echo esc_url(admin_url('admin-post.php')); ?>" method="post">
          <input type="hidden" name="action" value="kanz_save_fcm_key">
          <?php wp_nonce_field('kanz_save_fcm_key'); ?>
          <p><input type="file" accept=".json,application/json" onchange="var r=new FileReader();r.onload=function(e){document.getElementById('kanz-fcm-json-input').value=e.target.result;};r.readAsText(this.files[0]);"> <small>(اختيار ملف JSON تلقائياً)</small></p>
          <p><textarea id="kanz-fcm-json-input" name="fcm_service_account_json" required rows="5" style="width:100%;font-family:monospace" placeholder='{"type": "service_account", "project_id": "kanz-alsahra", ...}'></textarea></p>
          <button type="submit" class="button button-primary">حفظ وربط مفتاح Firebase</button>
        </form>
      </div>
    <?php } ?>
    <?php if (isset($_GET['notification']) && $_GET['notification'] === 'accepted') { ?><p>قبل Firebase الرسالة. هذا لا يضمن وصولها لكل جهاز.</p><?php } ?>
    <form action="<?php echo esc_url(admin_url('admin-post.php')); ?>" method="post">
      <input type="hidden" name="action" value="kanz_send_notification">
      <input type="hidden" name="request_id" value="<?php echo esc_attr(wp_generate_uuid4()); ?>">
      <p><label>الجمهور <select name="notification_audience"><option value="test_user" selected>اختبار حساب واحد فقط</option><option value="broadcast">إشعار عام لكل المشتركين</option></select></label></p>
      <p><label>رقم مستخدم WordPress للاختبار <input name="notification_test_user" type="number" min="1"></label></p>
      <p>الاختبار يستخدم جهاز الحساب المحفوظ في MStore فقط، ولا يشترك في customer_ID. عند غياب رمز الجهاز يفشل الاختبار دون إرسال عام. الإشعارات هنا للعروض فقط؛ ليست قناة مضمونة لبيانات الطلبات الخاصة.</p>
      <?php wp_nonce_field('kanz_send_notification'); ?>
      <p><label>العنوان <input required name="notification_title" maxlength="80" style="width:100%;max-width:400px"></label></p>
      <p><label>النص<br><textarea required name="notification_body" maxlength="800" rows="4" style="width:100%;max-width:550px"></textarea></label></p>
      <p><label>وجهة الإشعار <select name="destination_type" id="kanz-notif-dest-type">
        <?php foreach (array('none' => 'فتح التطبيق فقط', 'category' => 'تصنيف', 'product' => 'منتج', 'home' => 'الرئيسية', 'category_page' => 'صفحة التصنيفات', 'cart' => 'السلة', 'profile' => 'الحساب', 'url' => 'رابط HTTPS خارجي') as $key => $label) { ?><option value="<?php echo esc_attr($key); ?>"><?php echo esc_html($label); ?></option><?php } ?>
      </select></label></p>
      <p id="kanz-notif-row-category" style="display:none"><label>التصنيف
        <input type="search" placeholder="🔍 تصفية التصنيفات بالاسم..." oninput="kanzFilterSelect(this, 'kanz-notif-select-category')" style="display:block;margin:4px 0;width:100%;max-width:320px;padding:4px 8px;border:1px solid #ccc;border-radius:4px">
        <select name="destination_category" id="kanz-notif-select-category"><option value="">اختر التصنيف</option>
        <?php foreach (kanz_v3_destination_options('category') as $option) {
          $prefix = empty($option['parent']) ? '🟢 ' : '↳ ';
        ?><option value="<?php echo esc_attr($option['id']); ?>"><?php echo esc_html($prefix . $option['name'] . ' — #' . $option['id']); ?></option><?php } ?>
        </select></label></p>
      <p id="kanz-notif-row-product" style="display:none"><label>المنتج
        <input type="search" placeholder="🔍 تصفية المنتجات بالاسم..." oninput="kanzFilterSelect(this, 'kanz-notif-select-product')" style="display:block;margin:4px 0;width:100%;max-width:320px;padding:4px 8px;border:1px solid #ccc;border-radius:4px">
        <select name="destination_product" id="kanz-notif-select-product"><option value="">اختر المنتج</option>
        <?php foreach (kanz_v3_destination_options('product') as $option) { ?><option value="<?php echo esc_attr($option['id']); ?>"><?php echo esc_html($option['name'] . ' — #' . $option['id']); ?></option><?php } ?>
        </select></label></p>
      <p id="kanz-notif-row-url" style="display:none"><label>رابط خارجي <input name="destination_url" type="url" maxlength="2048" placeholder="https://..." style="width:100%;max-width:400px"></label></p>
      <script>
      function kanzFilterSelect(input, selectId) {
        var sel = document.getElementById(selectId);
        if (!sel) return;
        var term = input.value.trim().toLowerCase();
        for (var i = 0; i < sel.options.length; i++) {
          var opt = sel.options[i];
          if (!opt.value || !term) {
            opt.style.display = '';
          } else {
            opt.style.display = opt.text.toLowerCase().indexOf(term) !== -1 ? '' : 'none';
          }
        }
      }
      (function(){
        function updateNotifDest(){
          var sel = document.getElementById('kanz-notif-dest-type');
          if(!sel) return;
          var cat = document.getElementById('kanz-notif-row-category');
          var prod = document.getElementById('kanz-notif-row-product');
          var url = document.getElementById('kanz-notif-row-url');
          if(cat) cat.style.display = sel.value === 'category' ? 'block' : 'none';
          if(prod) prod.style.display = sel.value === 'product' ? 'block' : 'none';
          if(url) url.style.display = sel.value === 'url' ? 'block' : 'none';
        }
        var s = document.getElementById('kanz-notif-dest-type');
        if(s){ s.addEventListener('change', updateNotifDest); updateNotifDest(); }
      })();
      </script>
      <p>اختيار الوجهة لا يفعّل الإرسال. يلزم تحديث التطبيق لدعم الوجهات الجديدة. لا تستخدم الروابط لإجراءات حذف أو شراء أو بيانات خاصة.</p>
      <p><label><input required type="checkbox" name="confirm_broadcast" value="1">راجعت النص والجمهور المختار وأوافق على الإرسال، دون بيانات خاصة.</label></p>
      <button type="submit" class="button button-primary" <?php disabled(!$ready); ?>>إرسال إشعار عام</button>
    </form>
    <h3>سجل محاولات الإرسال</h3>
    <?php foreach (get_option('kanz_notification_history', array()) as $entry) { ?>
      <p><?php echo esc_html(gmdate('c', $entry['time']) . ' — ' . $entry['title'] . ' — ' . $entry['status']); ?></p>
    <?php } ?>
    <?php
}
function kanz_v3_config_validate($data) {
    if (!is_array($data) || !isset($data['Setting'], $data['TabBar'], $data['HorizonLayout']) ||
        !is_array($data['Setting']) || !is_array($data['TabBar']) || !$data['TabBar'] ||
        !is_array($data['HorizonLayout'])) {
        return new WP_Error('invalid_config', 'يلزم وجود Setting وTabBar وHorizonLayout صحيحة.');
    }
    foreach ($data['TabBar'] as $tab) {
        if (!is_array($tab) || empty($tab['layout']) || empty($tab['icon']) || !is_string($tab['layout']) || !is_string($tab['icon'])) {
            return new WP_Error('invalid_tabs', 'إعدادات شريط التنقل غير صحيحة.');
        }
    }
    foreach ($data['HorizonLayout'] as $section) {
        if (!is_array($section) || empty($section['layout']) || !is_string($section['layout'])) {
            return new WP_Error('invalid_sections', 'كل قسم يحتاج نوع عرض layout.');
        }
        if (isset($section['items']) && !is_array($section['items'])) {
            return new WP_Error('invalid_items', 'عناصر القسم يجب أن تكون قائمة.');
        }
    }
    if (isset($data['Setting']['DefaultTheme']) && !in_array($data['Setting']['DefaultTheme'], array('dark', 'light'), true)) {
        return new WP_Error('invalid_theme', 'المظهر الافتراضي يجب أن يكون داكناً أو فاتحاً.');
    }
    if (isset($data['KanzControl'])) {
        if (!is_array($data['KanzControl']) || !isset($data['KanzControl']['updates']) || !is_array($data['KanzControl']['updates'])) {
            return new WP_Error('invalid_updates', 'إعدادات التحديث غير صحيحة.');
        }
        foreach (array('android', 'ios') as $platform) {
            if (!isset($data['KanzControl']['updates'][$platform])) { continue; }
            $update = $data['KanzControl']['updates'][$platform];
            if (!is_array($update) || !isset($update['enabled']) || !is_bool($update['enabled']) ||
                !isset($update['minimumBuild']) || !is_int($update['minimumBuild']) || $update['minimumBuild'] < 0 ||
                $update['minimumBuild'] > 2147483647 || ($update['enabled'] && $update['minimumBuild'] < 1)) {
                return new WP_Error('invalid_updates', 'اختر حد إصدار صحيحاً؛ لا تفعّل الإجبار قبل نشر الإصدار فعلياً في المتجر.');
            }
        }
    }
    $walk = function ($value) use (&$walk) {
        if (is_array($value)) {
            foreach ($value as $key => $child) {
                if (preg_match('/^(consumer_?key|consumer_?secret|private_?key|service_account|password|authorization|cookie)$/i', (string) $key)) {
                    return false;
                }
                if (!$walk($child)) { return false; }
            }
        } elseif (is_string($value) && preg_match('/<\s*script\b|javascript\s*:|BEGIN (?:RSA )?PRIVATE KEY/i', $value)) {
            return false;
        }
        return true;
    };
    return $walk($data) ? true : new WP_Error('unsafe_config', 'لا تنشر أسراراً أو أكواداً تنفيذية في ملف التطبيق العام.');
}

add_action('admin_menu', function () {
    add_menu_page('إدارة تطبيق كنز', 'تطبيق كنز', 'manage_options', 'kanz-app-control', 'kanz_v3_config_page', 'dashicons-smartphone');
});

add_action('admin_enqueue_scripts', function ($hook) {
    if ($hook !== 'toplevel_page_kanz-app-control') { return; }
    wp_enqueue_media();
    wp_enqueue_script('jquery-core');
    $categories = array();
    if (taxonomy_exists('product_cat')) {
        $terms = get_terms(array('taxonomy' => 'product_cat', 'hide_empty' => false));
        if (!is_wp_error($terms)) {
            foreach ($terms as $term) {
                $categories[] = array(
                    'id' => (string) $term->term_id,
                    'name' => $term->name,
                    'parent' => (int) $term->parent,
                    'count' => (int) $term->count,
                );
            }
        }
    }
    wp_localize_script('jquery-core', 'kanzAdmin', array('categories' => $categories, 'products' => kanz_v3_destination_options('product')));
    wp_add_inline_script('jquery-core', kanz_v3_snippet_admin_js(), 'after');
});

function kanz_v3_mstore_path() {
    $uploads = wp_upload_dir();
    if (!empty($uploads['error'])) { return new WP_Error('upload_path', 'تعذر تحديد مجلد رفع MStore.'); }
    $root = realpath($uploads['basedir']);
    $candidate = class_exists('FlutterUtils') ? FlutterUtils::get_json_file_path('config_ar.json') : $uploads['basedir'] . '/flutter_config_files/config_ar.json';
    $path = realpath($candidate);
    if (!$root || !$path || basename($path) !== 'config_ar.json' || strpos(str_replace('\\', '/', $path), rtrim(str_replace('\\', '/', $root), '/') . '/') !== 0) {
        return new WP_Error('mstore_missing', 'لم يوجد config_ar.json داخل مجلد MStore. ارفعه من MStore أولاً.');
    }
    return $path;
}

function kanz_v3_mstore_record() {
    $path = kanz_v3_mstore_path();
    if (is_wp_error($path)) { return $path; }
    if (!is_readable($path) || filesize($path) > 1048576) { return new WP_Error('mstore_read', 'ملف MStore غير قابل للقراءة أو كبير جداً.'); }
    $raw = file_get_contents($path);
    $data = json_decode($raw, true, 64); $object = json_decode($raw, false, 64);
    if (!is_object($object) || kanz_v3_config_validate($data) !== true) { return new WP_Error('mstore_invalid', 'ملف MStore الحالي غير صالح؛ لم يتم استبداله.'); }
    return array('revision' => hash('sha256', $raw), 'saved_at' => gmdate('c', filemtime($path)), 'config' => $object);
}

function kanz_v3_mstore_publish($object, $expected_revision) {
    $path = kanz_v3_mstore_path();
    if (is_wp_error($path)) { return $path; }
    if (!is_writable($path) || !is_writable(dirname($path))) { return new WP_Error('mstore_readonly', 'WordPress لا يملك صلاحية كتابة ملف MStore؛ لم يتم النشر.'); }
    $json = wp_json_encode($object, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if (!is_string($json) || strlen($json) > 1048576) { return new WP_Error('mstore_encode', 'تعذر تجهيز الملف.'); }
    $temporary = tempnam(dirname($path), 'kanz-config-');
    if (!$temporary) { return new WP_Error('mstore_temp', 'تعذر تجهيز ملف مؤقت.'); }
    try {
        if (file_put_contents($temporary, $json, LOCK_EX) !== strlen($json)) { return new WP_Error('mstore_write', 'تعذر كتابة الملف؛ النسخة الحالية لم تتغير.'); }
        chmod($temporary, fileperms($path) & 0777);
        $actual_revision = is_file($path) ? hash_file('sha256', $path) : false;
        if (!is_string($actual_revision) || !hash_equals($expected_revision, $actual_revision)) { return new WP_Error('mstore_conflict', 'عدل مستخدم آخر الملف؛ أعد تحميل اللوحة قبل النشر.'); }
        if (!rename($temporary, $path)) { return new WP_Error('mstore_replace', 'تعذر استبدال ملف MStore.'); }
        clearstatcache(true, $path);
        if (function_exists('do_action')) { do_action('litespeed_purge_url', kanz_v3_mstore_url()); }
        return true;
    } finally { if (is_file($temporary)) { unlink($temporary); } }
}

function kanz_v3_mstore_url() {
    return class_exists('FlutterUtils') ? FlutterUtils::get_json_file_url('config_ar.json') : rtrim(wp_upload_dir()['baseurl'], '/') . '/flutter_config_files/config_ar.json';
}

add_action('admin_post_kanz_save_config', function () {
    if (!current_user_can('manage_options')) { wp_die('غير مصرح', '', array('response' => 403)); }
    check_admin_referer('kanz_save_config');
    $raw = isset($_POST['config_json']) ? wp_unslash($_POST['config_json']) : '';
    if (!is_string($raw) || strlen($raw) > 1048576) { wp_die('الملف كبير أو غير صالح.'); }
    $data = json_decode($raw, true, 64);
    if (json_last_error() !== JSON_ERROR_NONE || !is_array($data)) { wp_die('JSON غير صالح. لم تتغير النسخة المنشورة.'); }
    $object = json_decode($raw, false, 64);
    if (!is_object($object) || !isset($object->Setting) || !is_object($object->Setting) ||
        !isset($object->TabBar, $object->HorizonLayout) || !is_array($object->TabBar) || !is_array($object->HorizonLayout)) {
        wp_die('نوع حقول JSON غير صحيح. Setting يجب أن يكون كائناً والأقسام والتنقل قوائم.');
    }
    $valid = kanz_v3_config_validate($data);
    if (is_wp_error($valid)) { wp_die(esc_html($valid->get_error_message())); }
    foreach (array('android', 'ios') as $platform) {
        if (!empty($data['KanzControl']['updates'][$platform]['enabled']) && empty($_POST['confirm_updates'])) {
            wp_die('أكد توفر الإصدار المطلوب في المتجر قبل نشر إعدادات التحديث الإجباري.');
        }
    }
    // Unique option insertion provides a database-level publication lock.
    // A stale lock is intentionally NOT stolen during a running publication.
    if (!add_option('kanz_app_config_publish_lock', gmdate('c'), '', false)) {
        wp_die('هناك عملية نشر أخرى. انتظر ثم أعد المحاولة؛ إذا استمر التنبيه اطلب مراجعة قفل النشر من المسؤول.');
    }
    // Optimistic locking prevents silently overwriting another administrator.
    $current = kanz_v3_mstore_record();
    if (is_wp_error($current)) { delete_option('kanz_app_config_publish_lock'); wp_die(esc_html($current->get_error_message())); }
    $revision = isset($current['revision']) ? $current['revision'] : '';
    if (!isset($_POST['base_revision']) || !hash_equals((string) $revision, (string) wp_unslash($_POST['base_revision']))) {
        delete_option('kanz_app_config_publish_lock');
        wp_die('تغيرت النسخة منذ فتح الصفحة. انسخ تعديلك ثم أعد تحميل الصفحة.');
    }
    // Preserve {} versus [] exactly, including empty map-valued components.
    $record = array('revision' => wp_generate_uuid4(), 'saved_at' => gmdate('c'), 'user_id' => get_current_user_id(), 'config' => $object);
    $history = get_option('kanz_app_config_history', array());
    if (!empty($current)) { array_unshift($history, $current); }
    // Snapshot is written before replacing the publication.
    $next_history = array_slice($history, 0, 20);
    if ($history && !update_option('kanz_app_config_history', $next_history, false)) {
        delete_option('kanz_app_config_publish_lock');
        wp_die('تعذر حفظ النسخة السابقة. لم يتم النشر.');
    }
    $saved = kanz_v3_mstore_publish($object, (string) $revision);
    if (!is_wp_error($saved)) { update_option('kanz_app_config_record', $record, false); }
    delete_option('kanz_app_config_publish_lock');
    if (is_wp_error($saved)) { wp_die(esc_html($saved->get_error_message())); }
    wp_safe_redirect(admin_url('admin.php?page=kanz-app-control&saved=1'));
    exit;
});

add_action('rest_api_init', function () {
    register_rest_route('kanz/v1', '/config/(?P<locale>[a-zA-Z_-]+)', array(
        'methods' => 'GET', 'permission_callback' => '__return_true',
        'callback' => function () {
            $record = kanz_v3_mstore_record();
            if (is_wp_error($record)) { return new WP_Error('mstore_unavailable', 'Configuration is unavailable.', array('status' => 503)); }
            if (empty($record['config'])) { return new WP_Error('not_published', 'Configuration is not published.', array('status' => 404)); }
            // Never expose administrator identity, history or notification secrets.
            $response = new WP_REST_Response($record['config']);
            $response->header('Cache-Control', 'no-store');
            return $response;
        },
    ));
});

function kanz_v3_config_page() {
    if (!current_user_can('manage_options')) { return; }
    $record = kanz_v3_mstore_record();
    if (is_wp_error($record)) { echo '<div class="notice notice-error"><p>' . esc_html($record->get_error_message()) . '</p></div>'; return; }
    $json = empty($record['config']) ? '' : wp_json_encode($record['config'], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    ?>
    <div class="wrap" dir="rtl">
      <h1>إدارة تطبيق كنز الصحراء</h1>
      <?php if (isset($_GET['saved'])) { ?><div class="notice notice-success"><p>تم حفظ النسخة المنشورة.</p></div><?php } ?>
      <p>تقرأ اللوحة config_ar.json من MStore تلقائياً عند فتحها. زر النشر يستبدل الملف نفسه بعد حفظ نسخة سابقة. الاستيراد اليدوي اختياري للمسودة فقط.</p>
      <p>رابط إعدادات MStore: <code dir="ltr"><?php echo esc_html(kanz_v3_mstore_url()); ?></code></p>
      <p><strong>لا تعدل ملف MStore من واجهتين في الوقت نفسه. قد تحتاج التطبيقات إعادة فتح لجلب الإعدادات، والوظائف الجديدة تحتاج تحديث التطبيق. لا توجد حاجة لتغيير مصدر التطبيق إذا كان يقرأ هذا الرابط.</strong></p>
      <input id="kanz-import" type="file" accept=".json,application/json">
      <p id="kanz-error" role="alert" style="color:#b32d2e"></p>
      <form id="kanz-form" action="<?php echo esc_url(admin_url('admin-post.php')); ?>" method="post">
        <input type="hidden" name="action" value="kanz_save_config">
        <input type="hidden" name="base_revision" value="<?php echo esc_attr(isset($record['revision']) ? $record['revision'] : ''); ?>">
        <?php wp_nonce_field('kanz_save_config'); ?>
        <h2>أقسام الصفحة الرئيسية</h2>
        <p>رتّب الأقسام، وعدّل أسماء الأقسام وتصنيفاتها، وأضف صور البانرات من مكتبة الوسائط.</p>
        <div id="kanz-sections"></div>
        <button type="button" id="kanz-add-banner" class="button">إضافة بانر</button>
        <button type="button" id="kanz-add-category" class="button">إضافة قسم منتجات</button>
        <h2>المظهر الافتراضي للتطبيق</h2>
        <div id="kanz-appearance"></div>
        <h2>ترتيب التصنيفات في صفحة التصنيفات</h2>
        <p>الأسهم تغيّر ترتيب التصنيفات. تُحفظ القائمة كاملة عند تغيير الترتيب، دون حذف التصنيفات الأخرى. التصنيفات الجديدة لاحقاً تحتاج إعادة حفظ الترتيب.</p>
        <div id="kanz-category-order"></div>
        <h2>التحديث الإجباري</h2>
        <p>الحد هو رقم البناء، وليس الاسم مثل 1.10.2. لا تفعّله قبل توفر إصدار يمكن للعملاء تنزيله. يطبّق التطبيق سياسة الإعدادات المحفوظة عند فتحه من جديد؛ لا يقطع عملية دفع جارية إذا تغيرت الإعدادات أثناء الاستخدام.</p>
        <div id="kanz-updates"></div>
        <p><label><input id="kanz-confirm-updates" type="checkbox" name="confirm_updates" value="1">إذا كان التحديث الإجباري مفعلاً، أؤكد أن الإصدار المطلوب متاح للتنزيل فعلياً في المتجر.</label></p>
        <button type="button" id="kanz-export" class="button">تحميل JSON للنسخة الحالية</button>
        <details><summary>تعديل جميع حقول الإعدادات من اللوحة</summary>
          <p>يشمل الألوان والخطوط وبقية حقول الملف، مع الحفاظ على نوع كل قيمة. الحقول الجديدة لا تضيف وظائف غير مدعومة في التطبيق.</p>
          <div id="kanz-all-fields"></div>
        </details>
        <details style="margin-top:20px"><summary>الإعدادات الكاملة — تحرير JSON</summary>
          <p>يحافظ المحرر على الحقول الإضافية. اضغط «تطبيق النص على المحرر» قبل تعديل الأقسام بصرياً.</p>
          <textarea id="kanz-json" name="config_json" dir="ltr" spellcheck="false" style="width:100%;min-height:400px"><?php echo esc_textarea($json); ?></textarea>
          <button id="kanz-apply" type="button" class="button">تطبيق النص على المحرر</button>
        </details>
        <?php submit_button('نشر إعدادات التطبيق'); ?>
      </form>
      <h2>النسخ السابقة</h2>
      <p>يمكن تحميل نسخة سابقة واستيرادها للمراجعة، ثم نشرها. لا يوجد استرجاع تلقائي دون مراجعة.</p>
      <?php foreach (get_option('kanz_app_config_history', array()) as $past) { ?>
        <details><summary><?php echo esc_html($past['saved_at']); ?></summary><textarea readonly dir="ltr" style="width:100%;height:150px"><?php echo esc_textarea(wp_json_encode($past['config'], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)); ?></textarea></details>
      <?php } ?>
      <?php kanz_v3_notification_page_section(); ?>
    </div>
    <?php
}
}
