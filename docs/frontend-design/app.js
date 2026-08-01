(() => {
  const $ = (selector, root = document) => root.querySelector(selector);
  const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));

  const device = $('#device');
  const app = $('#app');
  const deviceStage = $('#deviceStage');
  const deviceToggle = $('#deviceToggle');
  const viewportLabel = $('#viewportLabel');
  const designModeNote = $('#designModeNote');
  const appScroll = $('#appScroll');
  const toast = $('#toast');
  const modalBackdrop = $('#modalBackdrop');
  const startPanel = $('#startPanel');

  const stageLabels = ['0', '1', '2', '4', '7', '15', '30', '90', '180'];
  const stageNames = ['新卡', '1 天', '2 天', '4 天', '7 天', '15 天', '30 天', '90 天', '180 天'];

  const decks = [
    { id: 'jp', name: '日语 N5', count: 64, due: 8, new: 3, flag: '日', scale: [1, 1, 1, 1, 1, 1, 0, 0, 0] },
    { id: 'sys', name: '系统设计', count: 58, due: 5, new: 1, flag: '系', scale: [1, 1, 1, 1, 0, 1, 0, 0, 0] },
    { id: 'anatomy', name: '人体解剖', count: 52, due: 4, new: 2, flag: '解', scale: [1, 0, 1, 1, 0, 1, 0, 0, 0] },
    { id: 'poetry', name: '唐诗三百首', count: 82, due: 1, new: 0, flag: '诗', scale: [0, 0, 0, 0, 0, 0, 1, 1, 0] }
  ];

  const allCards = [
    { id: 'c1', deck: 'jp', front: 'ありがとう', back: '谢谢（礼貌形）', stage: 3, next: '明天', due: false, learning: false },
    { id: 'c2', deck: 'jp', front: '勉強する', back: '学习；用功', stage: 1, next: '今天', due: true, learning: false },
    { id: 'c3', deck: 'jp', front: 'お願いします', back: '拜托了；请', stage: 0, next: '新卡', due: false, learning: false },
    { id: 'c4', deck: 'jp', front: '$$\\int_0^1 x^2\\,dx$$', back: '$$\\frac{1}{3}$$', stage: 2, next: '今天', due: true, learning: true },
    { id: 'c5', deck: 'sys', front: '为何复习间隔要逐级增加？', back: '让记忆强度与遗忘曲线匹配', stage: 5, next: '15 天后', due: false, learning: false },
    { id: 'c6', deck: 'sys', front: 'VAGUE 后需要几次熟悉？', back: '连续 3 次，回到记录的目标级别', stage: 0, next: '今天', due: true, learning: true },
    { id: 'c7', deck: 'anatomy', front: '肱骨近端包括哪些结构？', back: '肱骨头、解剖颈、外科颈、大小结节', stage: 6, next: '30 天后', due: false, learning: false },
    { id: 'c8', deck: 'poetry', front: '“海上生明月”下一句？', back: '天涯共此时', stage: 7, next: '90 天后', due: false, learning: false }
  ];

  const reviewData = [
    {
      front: 'ありがとう',
      answer: '谢谢（礼貌形）',
      stage: 3,
      current: '4 天',
      familiar: '7 天',
      vague: '4 天',
      learning: false,
      familiarCount: 0,
      goal: 0
    },
    {
      front: '$$\\int_0^1 x^2\\,dx$$',
      answer: '$$\\frac{1}{3}$$',
      stage: 2,
      current: '2 天',
      familiar: '4 天',
      vague: '2 天',
      learning: true,
      familiarCount: 2,
      goal: 3
    },
    {
      front: 'git rebase -i HEAD~3',
      answer: '交互式整理最近三条提交',
      stage: 4,
      current: '7 天',
      familiar: '15 天',
      vague: '7 天',
      learning: false,
      familiarCount: 0,
      goal: 0
    }
  ];

  const stageDistribution = [5, 8, 6, 7, 5, 4, 3, 2, 2];

  let currentDeckId = 'jp';
  let cardFilter = 'all';
  let reviewIndex = 0;
  let reviewDone = false;
  let reviewedToday = 12;
  let dueToday = 18;
  let totalDecks = decks.length;
  let modalMode = 'deck';
  let editingCardId = null;
  let toastTimer = null;
  let startMode = 'review';
  let startDeck = 'all';
  let previousScreen = 'home';

  function escapeHtml(value) {
    return String(value).replace(/[&<>"']/g, (char) => ({
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;'
    }[char]));
  }

  function showToast(message) {
    toast.textContent = message;
    toast.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove('show'), 2400);
  }

  function buildRuler(container, current) {
    container.innerHTML = stageLabels.map((label, index) => `
      <span class="tick${index === current ? ' current' : ''}">
        <i></i>
        <span class="tick-label">${label}</span>
      </span>
    `).join('');
  }

  function renderDecks() {
    const deckRows = decks.map((deck) => `
      <button class="deck-row" type="button" data-action="open-cards" data-deck="${deck.id}">
        <span class="deck-flag">${deck.flag}</span>
        <span class="deck-copy">
          <span class="deck-name">${escapeHtml(deck.name)}</span>
          <span class="deck-meta">${deck.count} 张 · 待复习 ${deck.due}</span>
          <span class="mini-scale" aria-hidden="true">${deck.scale.map((on) => `<i class="${on ? 'on' : ''}"></i>`).join('')}</span>
        </span>
        <svg aria-hidden="true"><use href="#icon-chevron-right"></use></svg>
      </button>
    `).join('');
    $('#deckList').innerHTML = deckRows;
    $('#deckListPage').innerHTML = deckRows;
    $('#deckPageCount').textContent = `${decks.length} 个牌组`;
  }

  function renderCards() {
    const deckCards = allCards.filter((card) => card.deck === currentDeckId);
    const visibleCards = deckCards.filter((card) => {
      if (cardFilter === 'due') return card.due;
      if (cardFilter === 'learning') return card.learning;
      return true;
    });

    $('#deckTitle').textContent = decks.find((deck) => deck.id === currentDeckId)?.name || '牌组';
    const deck = decks.find((item) => item.id === currentDeckId);
    $('#deckCardCount').textContent = deck ? deck.count : 0;
    $('#deckDueCount').textContent = deck ? deck.due : 0;
    $('#filterAllCount').textContent = deckCards.length;
    $('#filterDueCount').textContent = deckCards.filter((card) => card.due).length;
    $('#filterLearningCount').textContent = deckCards.filter((card) => card.learning).length;

    $('#cardList').innerHTML = visibleCards.map((card) => `
      <button class="card-row" type="button" data-action="edit-card" data-card-id="${card.id}">
        <span class="card-row-top">
          <span class="stage-badge">${stageNames[card.stage] || card.stage}</span>
          ${card.learning ? '<span class="stage-badge learning">重学</span>' : ''}
          <span class="card-row-next">${escapeHtml(card.next)}</span>
        </span>
        <span class="card-front">${escapeHtml(card.front)}</span>
        <span class="card-back">${escapeHtml(card.back)}</span>
        <svg class="card-row-arrow" aria-hidden="true"><use href="#icon-chevron-right"></use></svg>
      </button>
    `).join('') || '<p class="muted">当前筛选下没有卡片。</p>';
  }

  function renderQueue() {
    $('#queueList').innerHTML = reviewData.map((card, index) => `
      <div class="queue-item${index === reviewIndex ? ' active' : ''}">
        <span class="queue-index">${String(index + 1).padStart(2, '0')}</span>
        <span class="queue-front">${escapeHtml(card.front)}</span>
      </div>
    `).join('');
  }

  function renderReview() {
    if (reviewDone) return;
    const card = reviewData[reviewIndex];

    $('#cardIndex').textContent = `${reviewIndex + 1} / ${reviewData.length}`;
    $('#cardQuestion').textContent = card.front;
    $('#cardAnswer').textContent = card.answer;
    $('#frontStage').textContent = `Stage ${card.stage} · ${card.current}`;
    $('#currentInterval').textContent = `当前间隔 ${card.current}`;
    $('#nextInterval').textContent = `熟悉后 ${card.familiar}`;
    $('#forgetSub').textContent = '重学';
    $('#vagueSub').textContent = card.vague;
    $('#familiarSub').textContent = card.familiar;
    $('#learningChip').hidden = !card.learning;
    $('#learningChip').textContent = `重学中 · ${card.familiarCount}/${card.goal}`;
    $('#reviewCount').textContent = `${reviewIndex + 1} / ${reviewData.length}`;
    $('#progressCaption').textContent = `${reviewIndex + 1} / ${reviewData.length}`;
    $('#reviewProgress').style.width = `${((reviewIndex + 1) / reviewData.length) * 100}%`;

    $('#flashCard').classList.remove('flipped', 'leaving', 'entering');
    $('#ratingPanel').hidden = true;
    $('#completePanel').hidden = true;
    $('#cardStack').hidden = false;

    buildRuler($('#reviewRuler'), card.stage);
    renderQueue();

    requestAnimationFrame(() => {
      $('#flashCard').classList.add('entering');
      setTimeout(() => $('#flashCard').classList.remove('entering'), 260);
    });
  }

  function openReview(mode = 'review') {
    reviewIndex = 0;
    reviewDone = false;
    $('#reviewModeTitle').textContent = mode === 'learn' ? '学习模式' : '复习模式';
    renderReview();
    go('review');
  }

  function restartReview() {
    reviewIndex = 0;
    reviewDone = false;
    renderReview();
    go('review');
  }
  function renderStartPanel() {
    const isLearn = startMode === 'learn';
    const totalCount = decks.reduce((sum, deck) => sum + (isLearn ? deck.new : deck.due), 0);
    const selectedDeck = decks.find((deck) => deck.id === startDeck);

    $('#startTitle').textContent = isLearn ? '开始学习' : '开始复习';
    $('#startCta').textContent = isLearn ? '开始学习' : '开始复习';
    $('#modeCountSummary').textContent = `${totalCount} 张`;
    $('#deckScopeSummary').textContent = startDeck === 'all' ? '全部卡组' : (selectedDeck?.name || '全部卡组');

    $$('.mode-option').forEach((option) => {
      option.classList.toggle('active', option.dataset.mode === startMode);
    });

    const options = [
      { id: 'all', name: '全部卡组', meta: `全部 ${totalCount}` },
      ...decks.map((deck) => ({
        id: deck.id,
        name: deck.name,
        meta: isLearn ? `新卡 ${deck.new}` : `待复习 ${deck.due}`
      }))
    ];

    $('#deckOptions').innerHTML = options.map((option) => `
      <button class="deck-option${startDeck === option.id ? ' active' : ''}" type="button" data-deck-option="${option.id}">
        <span class="deck-option-radio" aria-hidden="true"></span>
        <span class="deck-option-copy">
          <strong>${escapeHtml(option.name)}</strong>
          <small class="mono">${escapeHtml(option.meta)}</small>
        </span>
      </button>
    `).join('');
  }

  function openStartPanel() {
    startMode = 'review';
    startDeck = 'all';
    renderStartPanel();
    startPanel.hidden = false;
    startPanel.scrollTop = 0;
  }

  function closeStartPanel() {
    startPanel.hidden = true;
  }

  function setStartMode(mode) {
    startMode = mode;
    renderStartPanel();
  }

  function setStartDeck(deckId) {
    startDeck = deckId;
    renderStartPanel();
  }

  function startConfirmed() {
    const deckName = startDeck === 'all' ? '全部卡组' : (decks.find((deck) => deck.id === startDeck)?.name || '全部卡组');
    closeStartPanel();
    openReview(startMode);
    showToast(`${startMode === 'learn' ? '学习' : '复习'}已开始：${deckName}`);
  }

  function flipCard() {
    if (reviewDone) return;
    const flashCard = $('#flashCard');
    flashCard.classList.toggle('flipped');
    $('#ratingPanel').hidden = !flashCard.classList.contains('flipped');
  }

  function rateCard(rating) {
    if (reviewDone) return;
    const card = reviewData[reviewIndex];
    const labelMap = { FORGET: '忘记', VAGUE: '模糊', FAMILIAR: '熟悉' };
    const nextMap = { FORGET: '重学', VAGUE: card.vague, FAMILIAR: card.familiar };
    const nextLabel = nextMap[rating] || '已更新';

    reviewedToday += 1;
    dueToday = Math.max(0, dueToday - 1);
    $('#focusNumber').textContent = dueToday;
    $('#focusNote').textContent = `已复习 ${reviewedToday} · 还剩 ${dueToday}`;
    $('#dueTodayMetric').textContent = dueToday;
    $('#reviewedTodayMetric').textContent = reviewedToday;
    $('#completeSummary').textContent = `本次 ${reviewData.length} 张 · 已复习 ${reviewedToday} / 18`;

    showToast(`已评分：${labelMap[rating] || rating} · 下次 ${nextLabel}`);
    $('#flashCard').classList.add('leaving');

    setTimeout(() => {
      reviewIndex += 1;
      if (reviewIndex >= reviewData.length) {
        reviewDone = true;
        $('#reviewCount').textContent = `${reviewData.length} / ${reviewData.length}`;
        $('#progressCaption').textContent = `${reviewData.length} / ${reviewData.length}`;
        $('#reviewProgress').style.width = '100%';
        $('#cardStack').hidden = true;
        $('#ratingPanel').hidden = true;
        $('#completePanel').hidden = false;
        renderQueue();
        return;
      }
      renderReview();
    }, 260);
  }

  function renderStageBars() {
    $('#stageBars').innerHTML = stageDistribution.map((value, index) => `
      <div class="stage-bar">
        <i style="height:${Math.max(4, (value / 8) * 100)}%"></i>
        <span>${stageLabels[index]}</span>
      </div>
    `).join('');
  }

  function go(screen) {
    if (!['cards', 'review'].includes(screen)) previousScreen = screen;
    $$('.screen').forEach((item) => item.classList.toggle('active', item.dataset.screen === screen));
    app.classList.toggle('no-nav', screen === 'cards');
    const navMap = { home: 'home', cards: 'decks', decks: 'decks', review: 'review', stats: 'stats', settings: 'settings' };
    $$('.nav-item').forEach((item) => item.classList.toggle('active', item.dataset.nav === navMap[screen]));
    appScroll.scrollTop = 0;
  }

  function openCards(deckId) {
    currentDeckId = deckId;
    cardFilter = 'all';
    $$('.chip').forEach((chip) => chip.classList.toggle('active', chip.dataset.filter === 'all'));
    renderCards();
    go('cards');
  }

  function openModal(mode, card) {
    modalMode = mode;
    editingCardId = card ? card.id : null;
    $('#modalBackdrop').hidden = false;
    $('#modalHint').hidden = true;

    if (mode === 'deck') {
      $('#modalTitle').textContent = '新建牌组';
      $('#fieldOneLabel').textContent = '牌组名称';
      $('#fieldOne').value = '';
      $('#fieldTwoWrap').hidden = true;
      $('#fieldThreeWrap').hidden = true;
      $('#modalSave').textContent = '创建';
    } else if (mode === 'card') {
      $('#modalTitle').textContent = card ? '编辑卡片' : '新建卡片';
      $('#fieldOneLabel').textContent = '正面';
      $('#fieldOne').value = card ? card.front : '';
      $('#fieldTwoLabel').textContent = '反面';
      $('#fieldTwo').value = card ? card.back : '';
      $('#fieldTwoWrap').hidden = false;
      $('#fieldThreeWrap').hidden = true;
      $('#modalSave').textContent = card ? '保存' : '创建';
    } else if (mode === 'confirm-import') {
      $('#modalTitle').textContent = '导入数据';
      $('#modalHint').textContent = '导入将覆盖当前所有数据，此操作不可逆。确定要继续吗？';
      $('#modalHint').hidden = false;
      $('#fieldOne').value = '';
      $('#fieldTwo').value = '';
      $('#fieldTwoWrap').hidden = true;
      $('#fieldThreeWrap').hidden = true;
      $('#modalSave').textContent = '确定导入';
      $('#modalSave').classList.add('danger');
    }

    setTimeout(() => $('#fieldOne').focus(), 60);
  }

  function closeModal() {
    $('#modalBackdrop').hidden = true;
    $('#modalSave').classList.remove('danger');
  }

  function saveModal() {
    if (modalMode === 'deck') {
      const name = $('#fieldOne').value.trim();
      if (!name) return;
      decks.push({ id: `deck-${Date.now()}`, name, count: 0, due: 0, flag: name.slice(0, 1), scale: [0, 0, 0, 0, 0, 0, 0, 0, 0] });
      totalDecks += 1;
      $('#totalDecksMetric').textContent = totalDecks;
      renderDecks();
      showToast(`牌组已创建：${name}`);
      closeModal();
      return;
    }

    if (modalMode === 'card') {
      const front = $('#fieldOne').value.trim();
      const back = $('#fieldTwo').value.trim();
      if (!front || !back) return;
      if (editingCardId) {
        const card = allCards.find((item) => item.id === editingCardId);
        if (card) {
          card.front = front;
          card.back = back;
        }
        showToast('卡片已保存');
      } else {
        allCards.push({
          id: `card-${Date.now()}`,
          deck: currentDeckId,
          front,
          back,
          stage: 0,
          next: '新卡',
          due: false,
          learning: false
        });
        showToast('卡片已创建');
      }
      renderCards();
      closeModal();
      return;
    }

    if (modalMode === 'confirm-import') {
      showToast('数据已恢复：4 个牌组，256 张卡片');
      closeModal();
    }
  }

  function handleAction(action, element) {
    switch (action) {
      case 'start-review':
        openStartPanel();
        break;
      case 'open-review':
        openReview();
        break;
      case 'close-start':
        closeStartPanel();
        break;
      case 'start-confirm':
        startConfirmed();
        break;
      case 'back-home':
        go(previousScreen || 'home');
        break;
      case 'open-cards':
        openCards(element.dataset.deck || currentDeckId);
        break;
      case 'new-deck':
        openModal('deck');
        break;
      case 'new-card':
        openModal('card');
        break;
      case 'edit-card': {
        const card = allCards.find((item) => item.id === element.dataset.cardId);
        if (card) openModal('card', card);
        break;
      }
      case 'export-data':
        showToast('备份已导出为 JSON');
        break;
      case 'import-data':
        openModal('confirm-import');
        break;
      case 'logout':
        showToast('已退出登录');
        break;
      case 'restart-review':
        restartReview();
        break;
    }
  }

  function handleNav(nav) {
    if (nav === 'review') {
      openReview();
    } else if (nav === 'decks') {
      go('decks');
    } else {
      go(nav);
    }
  }

  document.addEventListener('click', (event) => {
    const actionElement = event.target.closest('[data-action]');
    if (actionElement) {
      handleAction(actionElement.dataset.action, actionElement);
      return;
    }
    const modeButton = event.target.closest('[data-mode]');
    if (modeButton) {
      setStartMode(modeButton.dataset.mode);
      return;
    }

    const deckOption = event.target.closest('[data-deck-option]');
    if (deckOption) {
      setStartDeck(deckOption.dataset.deckOption);
      return;
    }

    const ratingButton = event.target.closest('[data-rating]');
    if (ratingButton) {
      rateCard(ratingButton.dataset.rating);
      return;
    }

    const filterButton = event.target.closest('[data-filter]');
    if (filterButton) {
      cardFilter = filterButton.dataset.filter;
      $$('.chip').forEach((chip) => chip.classList.toggle('active', chip === filterButton));
      renderCards();
      return;
    }

    const navButton = event.target.closest('[data-nav]');
    if (navButton) {
      handleNav(navButton.dataset.nav);
    }
  });

  $('#flashCard').addEventListener('click', flipCard);
  $('#flashCard').addEventListener('keydown', (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      flipCard();
    }
  });

  $('#modalCancel').addEventListener('click', closeModal);
  $('#modalSave').addEventListener('click', saveModal);
  modalBackdrop.addEventListener('click', (event) => {
    if (event.target === modalBackdrop) closeModal();
  });

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !startPanel.hidden) {
      closeStartPanel();
    } else if (event.key === 'Escape' && !modalBackdrop.hidden) {
      closeModal();
    }
  });

  $('#refreshTime').addEventListener('change', (event) => {
    showToast(`刷新时间已保存：${event.target.value}`);
  });

  function updateScale() {
    const isTablet = device.classList.contains('tablet');
    const deviceWidth = isTablet ? 940 : 390;
    const deviceHeight = isTablet ? 680 : 844;
    const available = deviceStage.clientWidth || window.innerWidth - 48;
    const scale = Math.min(1, Math.max(.42, available / deviceWidth));
    device.style.setProperty('--device-scale', scale);
    deviceStage.style.minHeight = `${Math.round(deviceHeight * scale) + 48}px`;
  }

  function setDeviceMode(isTablet, announce = true) {
    device.classList.toggle('tablet', isTablet);
    deviceToggle.textContent = isTablet ? '切换手机' : '切换平板';
    deviceToggle.setAttribute('aria-pressed', isTablet ? 'true' : 'false');
    viewportLabel.textContent = isTablet ? '平板 940×680' : '手机 390×844';
    designModeNote.textContent = isTablet ? '平板布局：顶部悬浮导航，内容双栏呈现。' : '手机布局：底部悬浮药丸导航，单栏信息。';
    updateScale();
    if (announce) showToast(isTablet ? '已切换为平板布局' : '已切换为手机布局');
  }

  deviceToggle.addEventListener('click', () => {
    setDeviceMode(!device.classList.contains('tablet'));
  });

  const now = new Date();
  $('#todayTitle').textContent = new Intl.DateTimeFormat('zh-CN', { month: 'long', day: 'numeric', weekday: 'long' }).format(now);
  $('#statusTime').textContent = new Intl.DateTimeFormat('zh-CN', { hour: '2-digit', minute: '2-digit', hour12: false }).format(now).replace('24:', '00:');

  if (new URLSearchParams(window.location.search).has('tablet')) {
    setDeviceMode(true, false);
  }

  renderDecks();
  renderCards();
  renderReview();
  renderStageBars();
  buildRuler($('#homeRuler'), 4);
  updateScale();

  if ('ResizeObserver' in window) {
    new ResizeObserver(updateScale).observe(deviceStage);
  } else {
    window.addEventListener('resize', updateScale);
  }
})();
