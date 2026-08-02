const fs = require('fs');
const path = require('path');

let playwrightCorePath;
try {
  playwrightCorePath = require.resolve('playwright-core');
} catch (_) {
  playwrightCorePath = process.env.PLAYWRIGHT_CORE_PATH;
  if (!playwrightCorePath) {
    throw new Error('未找到 playwright-core。请在 tools/screenshots 下执行 npm install，或设置 PLAYWRIGHT_CORE_PATH。');
  }
}

const { chromium } = require(playwrightCorePath);

const ROOT = path.resolve(__dirname, '..', '..');
const OUTPUT_ROOT = path.join(ROOT, 'docs', 'frontend-design', 'screenshots');
const BASE_URL = process.env.KARIS_WEB_URL || 'http://localhost:8082';
const API_URL = process.env.KARIS_API_URL || 'http://localhost:8080/api';
const PASSWORD = 'password123';

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function api(route, token, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) };
  if (token) headers.Authorization = `Bearer ${token}`;
  const response = await fetch(`${API_URL}${route}`, { ...options, headers });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`${route} ${response.status} ${JSON.stringify(body)}`);
  }
  return body.data;
}

async function registerUser(prefix) {
  const email = `${prefix}-${Date.now()}@example.com`;
  const data = await api('/auth/register', null, {
    method: 'POST',
    body: JSON.stringify({ email, password: PASSWORD }),
  });
  return { email, password: PASSWORD, token: data.token };
}

async function rateCard(token, cardId, rating) {
  await api(`/review/${cardId}/rate`, token, {
    method: 'POST',
    body: JSON.stringify({ rating }),
  });
}

async function createDemoData(token) {
  const deckNames = ['日语 N5', '系统设计'];
  const cardSets = [
    [
      ['ありがとう', '谢谢（礼貌形）'],
      ['勉強する', '学习；用功'],
      ['お願いします', '拜托了；请'],
      ['$$\\int_0^1 x^2\\,dx$$', '$$\\frac{1}{3}$$'],
    ],
    [
      ['CAP 定理指什么？', '一致性、可用性、分区容错性'],
      ['REST 幂等性如何保证？', '使用幂等键或确定性的 PUT/DELETE'],
      ['git rebase -i HEAD~3', '交互式整理最近三条提交'],
    ],
  ];

  for (let i = 0; i < deckNames.length; i++) {
    const deck = await api('/decks', token, {
      method: 'POST',
      body: JSON.stringify({ name: deckNames[i] }),
    });

    const cardIds = [];
    for (const [front, back] of cardSets[i]) {
      const card = await api(`/decks/${deck.id}/cards`, token, {
        method: 'POST',
        body: JSON.stringify({ front, back }),
      });
      cardIds.push(card.id);
    }

    if (i === 0) {
      await rateCard(token, cardIds[0], 'FAMILIAR');
      await rateCard(token, cardIds[1], 'FAMILIAR');
      await rateCard(token, cardIds[1], 'FAMILIAR');
      await rateCard(token, cardIds[2], 'FAMILIAR');
      await rateCard(token, cardIds[2], 'FAMILIAR');
      await rateCard(token, cardIds[2], 'FAMILIAR');
      await rateCard(token, cardIds[3], 'FAMILIAR');
      await rateCard(token, cardIds[3], 'FAMILIAR');
      await rateCard(token, cardIds[3], 'FAMILIAR');
      await rateCard(token, cardIds[3], 'VAGUE');
    } else {
      await rateCard(token, cardIds[0], 'FAMILIAR');
      await rateCard(token, cardIds[1], 'VAGUE');
      await rateCard(token, cardIds[2], 'FAMILIAR');
      await rateCard(token, cardIds[2], 'FAMILIAR');
      await rateCard(token, cardIds[2], 'FAMILIAR');
      await rateCard(token, cardIds[2], 'FAMILIAR');
    }
  }
}

async function enableSemantics(page) {
  await page.evaluate(() => {
    const element = document.querySelector('flt-semantics-placeholder');
    if (element) {
      element.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
    }
  });
  await sleep(700);
}

async function openApp(page) {
  await page.goto(BASE_URL, { waitUntil: 'networkidle', timeout: 60000 });
  await sleep(3000);
  await enableSemantics(page);
}

async function bodyText(page) {
  return page.evaluate(() => document.body.innerText || '');
}

async function clickButton(page, text, { exact = false } = {}) {
  const pattern = exact ? new RegExp(`^${text}$`) : text;
  const locator = page.locator('flt-semantics[role="button"]', { hasText: pattern }).first();
  const count = await locator.count();
  if (count === 0) {
    throw new Error(`找不到按钮：${text}`);
  }
  await locator.click();
  await sleep(1200);
}

async function clickAria(page, text) {
  let locator = page.locator(`flt-semantics[aria-label*="${text}"]`).first();
  let count = await locator.count();
  if (count === 0) {
    locator = page.locator('flt-semantics[role="button"]', { hasText: text }).first();
    count = await locator.count();
  }
  if (count === 0) {
    throw new Error(`找不到语义节点：${text}`);
  }
  await locator.click();
  await sleep(1200);
}

async function shot(page, dir, name) {
  fs.mkdirSync(dir, { recursive: true });
  const target = path.join(dir, name);
  await page.screenshot({ path: target, fullPage: false });
  console.log('saved', path.relative(ROOT, target));
}

function cleanOutputDir(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
}

async function login(page, account) {
  await page.locator('input[aria-label="邮箱"]').fill(account.email);
  await page.locator('input[aria-label="密码"]').fill(account.password);
  await clickButton(page, '登录', { exact: true });
  await sleep(2600);
}

async function goNav(page, label) {
  await clickButton(page, label, { exact: true });
  await sleep(1800);
}

async function captureAuthAndHome(page, account, dir) {
  await openApp(page);
  await shot(page, dir, '01-login.png');

  await clickButton(page, '没有账号？立即注册');
  await shot(page, dir, '02-register.png');
  await clickButton(page, '已有账号？立即登录');

  await login(page, account);
  await shot(page, dir, '03-home.png');
}

async function captureStart(page, dir) {
  await clickButton(page, '开始');
  await clickButton(page, '学习新卡');
  await shot(page, dir, '04-start-flow.png');
  await clickButton(page, '返回');
  await sleep(1400);
}

async function captureDecks(page, dir) {
  await goNav(page, '卡组');
  await shot(page, dir, '05-decks.png');

  await clickButton(page, '新建牌组');
  await sleep(700);
  const deckNameInput = page.locator('input[aria-label*="牌组名称"]');
  if (await deckNameInput.count()) {
    await deckNameInput.fill('演示牌组');
  }
  await shot(page, dir, '06-deck-dialog.png');
  await clickButton(page, '取消', { exact: true });
  await sleep(800);
}

async function captureCards(page, dir) {
  await goNav(page, '今日');
  await clickButton(page, '日语 N5');
  await sleep(2200);
  await shot(page, dir, '07-cards.png');

  await clickButton(page, '新卡片');
  await sleep(1500);
  await shot(page, dir, '08-card-editor-front.png');
  await clickAria(page, '反面');
  await sleep(1000);
  await shot(page, dir, '09-card-editor-back.png');
  await clickAria(page, '返回');
  await sleep(900);

  await clickAria(page, '导入卡片');
  await sleep(1500);
  await shot(page, dir, '10-card-import.png');
  await clickAria(page, '返回');
  await sleep(900);
}

async function captureReview(page, dir) {
  await clickAria(page, '复习当前牌组');
  await sleep(2000);
  await shot(page, dir, '11-review-front.png');

  await clickAria(page, '闪卡');
  await sleep(1100);
  await shot(page, dir, '12-review-back.png');

  for (let i = 0; i < 10; i++) {
    const text = await bodyText(page);
    if (text.includes('复习完成') || text.includes('本轮学习完成')) break;
    const familiar = page.locator('flt-semantics[role="button"]', { hasText: '熟悉' }).first();
    if ((await familiar.count()) === 0) {
      await clickAria(page, '闪卡');
      continue;
    }
    await familiar.click();
    await sleep(1200);
  }
  await sleep(4200);
  await shot(page, dir, '13-review-complete.png');
  await clickButton(page, '返回今日');
  await sleep(1500);
}

async function captureStatsAndSettings(page, dir) {
  await goNav(page, '统计');
  await shot(page, dir, '14-stats.png');
  await goNav(page, '设置');
  await shot(page, dir, '15-settings.png');
}

async function captureDevice(browser, viewport, account, deviceName) {
  const dir = path.join(OUTPUT_ROOT, deviceName);
  cleanOutputDir(dir);
  const page = await browser.newPage({ viewport });
  try {
    await captureAuthAndHome(page, account, dir);
    await captureStart(page, dir);
    await captureDecks(page, dir);
    await captureCards(page, dir);
    await captureReview(page, dir);
    await captureStatsAndSettings(page, dir);
  } finally {
    await page.close();
  }
}

(async () => {
  const mobileAccount = await registerUser('mobile');
  await createDemoData(mobileAccount.token);
  const tabletAccount = await registerUser('tablet');
  await createDemoData(tabletAccount.token);

  const browser = await chromium.launch({
    executablePath: process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true,
  });

  try {
    await captureDevice(browser, { width: 390, height: 844 }, mobileAccount, 'mobile');
    await captureDevice(browser, { width: 940, height: 680 }, tabletAccount, 'tablet');
  } finally {
    await browser.close();
  }

  console.log('screenshots complete');
})();
