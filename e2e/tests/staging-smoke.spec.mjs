import { expect, test } from '@playwright/test';

const adminEmail = process.env.E2E_ADMIN_EMAIL;
const adminPassword = process.env.E2E_ADMIN_PASSWORD;

const requiredEnv = {
  E2E_ADMIN_EMAIL: adminEmail,
  E2E_ADMIN_PASSWORD: adminPassword,
};

test.beforeAll(() => {
  const missing = Object.entries(requiredEnv)
    .filter(([, value]) => !value)
    .map(([name]) => name);

  if (missing.length > 0) {
    throw new Error(`Missing required env vars: ${missing.join(', ')}`);
  }
});

test('admin can smoke test staging tabs without changing data', async ({
  page,
}) => {
  await signInAsAdmin(page);

  await expectAppShell(page);
  await expectRoute(page, '/', /Build your full 2026 World Cup bracket|Welcome/i);
  await expectRoute(page, '/bracket', /Your Bracket|Group Picks|Champion/i);
  await expectRoute(page, '/standings', /Standings/i);
  await expectRoute(page, '/amys-calendar', /Amy's Calendar|Today's games/i);
  await expectRoute(page, '/schedule', /Amy's Calendar|Today's games/i);
  await expectRoute(page, '/players', /Players/i);
  await expectRoute(page, '/leaderboard', /Global Leaderboard|Rank/i);
  await expectRoute(page, '/profile', /Profile|Sign out|Bracket/i);

  await expectAdminSections(page);
});

async function signInAsAdmin(page) {
  await page.goto('/#/admin');
  await waitForFlutter(page);

  await expect(page.getByText(/Admin Login|Admin sign in/i)).toBeVisible();
  await page.getByLabel(/Password/i).fill(adminPassword);
  await page.getByRole('button', { name: /^Sign in$/i }).click();

  await expect(page.getByText(/Admin Console/i)).toBeVisible({
    timeout: 30_000,
  });
}

async function expectAppShell(page) {
  await expect(
    page.getByText(/Ricky's World Cup Bracket 2026/i).first(),
  ).toBeVisible();
}

async function expectRoute(page, hashPath, expectedText) {
  await page.goto(`/#${hashPath}`);
  await waitForFlutter(page);
  await expect(page.getByText(expectedText).first()).toBeVisible();
}

async function expectAdminSections(page) {
  await page.goto('/#/admin');
  await waitForFlutter(page);
  await expect(page.getByText(/Admin Console/i)).toBeVisible();

  const sections = [
    {
      tab: /Games & results/i,
      content: /Games & Results|Save result and recalculate/i,
    },
    {
      tab: /Group advancers/i,
      content: /Confirm Group Advancers|Save group advancers/i,
    },
    {
      tab: /^Standings$/i,
      content: /Group Standings|Recalculate standings/i,
    },
    {
      tab: /^Leaderboard$/i,
      content: /Recalculate Leaderboard|Recalculate now/i,
    },
    {
      tab: /^Settings$/i,
      content: /Manage Contest Settings|Accepting submissions/i,
    },
    {
      tab: /Audit log/i,
      content: /Audit Log|No audit entries yet|result|settings|leaderboard/i,
    },
  ];

  for (const section of sections) {
    await page.getByText(section.tab).first().click();
    await expect(page.getByText(section.content).first()).toBeVisible();
  }
}

async function waitForFlutter(page) {
  await page.waitForLoadState('domcontentloaded');
  await page.locator('flt-glass-pane, flutter-view, body').first().waitFor();
  await page.evaluate(() => {
    document.querySelectorAll('flt-semantics-placeholder').forEach((node) => {
      if (node instanceof HTMLElement) node.click();
    });
  });
}
