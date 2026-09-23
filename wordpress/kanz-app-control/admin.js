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
      enableBackground: true,
    };
  }
  function render() {
    container.replaceChildren();
    if (!config) return;
    renderUpdates();
    renderAppearance();
    renderDrawer();
    renderAllFields();
    renderCategoryOrder();
    renderFilterCategoryOrder();
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
  function renderFilterCategoryOrder() {
    const panel = document.getElementById('kanz-filter-category-order'); if (!panel) return;
    panel.replaceChildren();
    const tab = config.TabBar.find((item) => item.layout === 'category'); if (!tab) return;
    const available = kanzAdmin.categories || [];
    const pageOrder = Array.isArray(tab.categories) ? tab.categories.map(String) : [];
    const allIds = [...new Set([...pageOrder, ...available.map((item) => String(item.id))])];
    if (!Array.isArray(tab.filterCategories)) {
      tab.filterCategories = allIds.filter((id) => {
        const category = available.find((item) => String(item.id) === id);
        return category?.isUncategorized !== true;
      });
      sync();
    }
    const visible = tab.filterCategories.map(String).filter((id) => allIds.includes(id));
    tab.filterCategories = visible;

    const note = document.createElement('p');
    note.textContent = 'فعّل التصنيفات التي تريد ظهورها داخل فلتر المنتجات ورتّبها بصورة مستقلة عن صفحة التصنيفات. أقسام أحدث المنتجات وعروض اليوم الوطني تبقى متاحة مثل بقية التصنيفات.';
    panel.append(note);
    const search = document.createElement('input');
    search.type = 'search'; search.placeholder = '🔍 ابحث في تصنيفات الفلتر...';
    search.style.cssText = 'display:block;width:100%;max-width:650px;padding:8px 12px;margin:8px 0 12px;border:1px solid #ccd0d4;border-radius:6px';
    panel.append(search);
    const list = document.createElement('div'); panel.append(list);

    const renderList = () => {
      list.replaceChildren();
      const query = search.value.trim().toLowerCase();
      const ordered = [...visible, ...allIds.filter((id) => !visible.includes(id))];
      ordered.forEach((id) => {
        const category = available.find((item) => String(item.id) === id);
        const name = category?.name || `تصنيف #${id}`;
        if (query && !name.toLowerCase().includes(query) && !id.includes(query)) return;
        const enabled = visible.includes(id);
        const row = document.createElement('div');
        row.style.cssText = `display:flex;align-items:center;justify-content:space-between;padding:8px 12px;margin:6px 0;max-width:650px;border:1px solid #ddd;border-radius:6px;background:${enabled ? '#f8fff8' : '#f4f4f4'}`;
        const identity = document.createElement('label');
        identity.style.cssText = 'display:flex;align-items:center;gap:8px;font-weight:600';
        const checkbox = document.createElement('input'); checkbox.type = 'checkbox'; checkbox.checked = enabled;
        checkbox.addEventListener('change', () => change(() => {
          if (checkbox.checked) {
            if (!visible.includes(id)) visible.push(id);
          } else {
            if (visible.length === 1) {
              checkbox.checked = true;
              throw new Error('يجب إبقاء تصنيف واحد على الأقل ظاهراً في الفلتر.');
            }
            const index = visible.indexOf(id);
            if (index !== -1) visible.splice(index, 1);
          }
          tab.filterCategories = [...visible];
        }));
        const parent = category?.parent
          ? available.find((item) => String(item.id) === String(category.parent))?.name
          : '';
        identity.append(checkbox, `${name}${parent ? ` — فرعي من ${parent}` : ''}`);
        row.append(identity);
        const actions = document.createElement('div'); actions.style.cssText = 'display:flex;align-items:center;gap:3px';
        if (enabled) {
          const index = visible.indexOf(id);
          const position = document.createElement('input'); position.type = 'number'; position.min = '1'; position.max = String(visible.length); position.step = '1'; position.value = String(index + 1);
          position.style.cssText = 'width:52px;text-align:center';
          position.addEventListener('change', () => {
            const target = Number(position.value) - 1;
            if (!Number.isInteger(target) || target < 0 || target >= visible.length) { position.value = String(index + 1); return; }
            change(() => { visible.splice(target, 0, visible.splice(index, 1)[0]); tab.filterCategories = [...visible]; });
          });
          actions.append(position);
          button('↑', () => change(() => { if (index > 0) { [visible[index - 1], visible[index]] = [visible[index], visible[index - 1]]; tab.filterCategories = [...visible]; } }), actions);
          button('↓', () => change(() => { if (index + 1 < visible.length) { [visible[index + 1], visible[index]] = [visible[index], visible[index + 1]]; tab.filterCategories = [...visible]; } }), actions);
        }
        row.append(actions); list.append(row);
      });
    };
    search.addEventListener('input', renderList);
    renderList();
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
  function renderDrawer() {
    const panel = document.getElementById('kanz-drawer'); if (!panel) return;
    panel.replaceChildren();
    const drawer = config.KanzDrawerV2 || {
      enabled: false, showSearch: true, showTracking: true,
      showCorporate: true, hideEmptyCategories: true, rootCategoryIds: [],
    };
    const toggle = (key, label) => {
      const row = document.createElement('label');
      row.style.cssText = 'display:block;margin:10px 0';
      const input = document.createElement('input'); input.type = 'checkbox';
      input.checked = drawer[key] === true;
      input.addEventListener('change', () => change(() => {
        config.KanzDrawerV2 = { ...drawer, [key]: input.checked };
      }));
      row.append(input, ` ${label}`); panel.append(row);
    };
    toggle('enabled', 'تفعيل القائمة الجديدة (تحتاج إصدار التطبيق الذي يدعمها)');
    toggle('showSearch', 'إظهار البحث');
    toggle('showTracking', 'تتبع شحنتك — فتح صفحة الموقع داخل التطبيق');
    toggle('showCorporate', 'طلبات الشركات — فتح صفحة الموقع داخل التطبيق');
    toggle('hideEmptyCategories', 'إخفاء التصنيفات الخالية من المنتجات');
    const note = document.createElement('p');
    note.textContent = 'تستعمل القائمة تصنيفات WooCommerce المتاحة داخل التطبيق. لا تضف هنا بيانات دخول أو روابط تتبع خاصة بالعملاء.';
    panel.append(note);
    const roots = (kanzAdmin.categories || []).filter((cat) =>
      Number(cat.parent) === 0 && cat.isUncategorized !== true);
    const selected = Array.isArray(drawer.rootCategoryIds) ? drawer.rootCategoryIds.map(String) : [];
    const title = document.createElement('h3'); title.textContent = 'الأقسام الرئيسية وترتيبها'; panel.append(title);
    button(selected.length ? 'العودة لأقسام الموقع الافتراضية' : 'تخصيص الأقسام', () => change(() => {
      config.KanzDrawerV2 = { ...drawer,
        rootCategoryIds: selected.length ? [] : roots.map((cat) => String(cat.id)) };
    }), panel);
    if (!selected.length) {
      const all = document.createElement('p'); all.textContent = 'تظهر أقسام الموقع الرئيسية الافتراضية: سبائك ذهب، جنيهات ذهب، أساور، سبائك فضة، أطقم الماس.'; panel.append(all);
      return;
    }
    selected.forEach((id, index) => {
      const cat = roots.find((item) => String(item.id) === id);
      const row = document.createElement('div'); row.style.cssText = 'margin:6px 0';
      row.append(`${cat?.name || `تصنيف #${id}`} `);
      button('↑', () => change(() => {
        if (index > 0) { [selected[index - 1], selected[index]] = [selected[index], selected[index - 1]]; config.KanzDrawerV2 = { ...drawer, rootCategoryIds: selected }; }
      }), row);
      button('↓', () => change(() => {
        if (index < selected.length - 1) { [selected[index + 1], selected[index]] = [selected[index], selected[index + 1]]; config.KanzDrawerV2 = { ...drawer, rootCategoryIds: selected }; }
      }), row);
      button('حذف', () => change(() => { selected.splice(index, 1); config.KanzDrawerV2 = { ...drawer, rootCategoryIds: selected }; }), row);
      panel.append(row);
    });
    const available = roots.filter((cat) => !selected.includes(String(cat.id)));
    if (available.length) {
      const select = document.createElement('select');
      available.forEach((cat) => { const option = document.createElement('option'); option.value = cat.id; option.textContent = cat.name; select.append(option); });
      panel.append(select);
      button('إضافة قسم', () => change(() => { selected.push(select.value); config.KanzDrawerV2 = { ...drawer, rootCategoryIds: selected }; }), panel);
    }
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
