
import 'dotenv/config';
import { test, expect, Page } from '@playwright/test';

type ProcessEnv = Record<string, string | undefined>;

const env = (
  globalThis as typeof globalThis & {
    process?: { env?: ProcessEnv };
  }
).process?.env ?? {};

const APP_URL = env.BASE_URL ?? 'https://ambulance-first.saikamalnukala28.workers.dev/';

const accounts = [
  { role: 'Customer', email: 'CUSTOMER_EMAIL', password: 'CUSTOMER_PASSWORD' },
  { role: 'Customer Care', email: 'CUSTOMER_CARE_EMAIL', password: 'CUSTOMER_CARE_PASSWORD' },
  { role: 'Driver', email: 'DRIVER_EMAIL', password: 'DRIVER_PASSWORD' },
  { role: 'Team Lead', email: 'TEAM_LEAD_EMAIL', password: 'TEAM_LEAD_PASSWORD' },
  { role: 'Admin', email: 'ADMIN_EMAIL', password: 'ADMIN_PASSWORD' },
];

test.setTimeout(90000);

async function openApp(page: Page) {
  await page.setViewportSize({ width: 1326, height: 700 });

  const response = await page.goto(APP_URL, {
    waitUntil: 'domcontentloaded',
    timeout: 45000,
  });

  expect(response).not.toBeNull();
  expect(response!.status()).toBeLessThan(400);
  await expect(page).toHaveTitle('Ambulance First');
  await page.waitForTimeout(3000);
}

test('App startup: deployed app loads', async ({ page }) => {
  await openApp(page);

  await page.screenshot({
    path: 'test-results/app-startup.png',
    fullPage: false,
  });
});

test('Login UI: empty submission validation', async ({ page }) => {
  await openApp(page);

  // Coordinates based on the login screen previously inspected.
  await page.mouse.click(660, 600);
  await page.waitForTimeout(1500);

  await page.screenshot({
    path: 'test-results/empty-login-validation.png',
    fullPage: false,
  });

  expect(await page.title()).toBe('Ambulance First');
});

for (const account of accounts) {
  test(`${account.role}: login flow`, async ({ page }) => {
    const email = env[account.email];
    const password = env[account.password];

    test.skip(
      !email || !password,
      `Missing ${account.email} or ${account.password} in .env`,
    );

    await openApp(page);

    // Coordinates match the previously verified login layout.
    await page.mouse.click(620, 386);
    await page.keyboard.type(email!);

    await page.mouse.click(620, 475);
    await page.keyboard.type(password!);

    await page.screenshot({
      path: `test-results/${account.role.toLowerCase().replace(/\s+/g, '-')}-credentials-entered.png`,
      fullPage: false,
    });

    // Submit credentials.
    await page.mouse.click(660, 600);
    await page.waitForTimeout(6000);

    console.log(`Role tested: ${account.role}`);
    console.log(`Resulting URL: ${page.url()}`);

    await page.screenshot({
      path: `test-results/${account.role.toLowerCase().replace(/\s+/g, '-')}-result.png`,
      fullPage: true,
    });

    // Basic smoke assertion only; dashboard verification comes next.
    await expect(page).toHaveTitle('Ambulance First');
  });
}
