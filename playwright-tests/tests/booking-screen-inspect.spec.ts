
import { test, expect } from '@playwright/test';
import 'dotenv/config';

declare const process: { env: Record<string, string | undefined> };

const APP_URL =
  process.env.BASE_URL ??
  'https://ambulance-first.saikamalnukala28.workers.dev/';

test('Customer login and booking dashboard discovery', async ({ page }) => {
  const email = process.env.CUSTOMER_EMAIL;
  const password = process.env.CUSTOMER_PASSWORD;

  expect(email, 'Set CUSTOMER_EMAIL in .env').toBeTruthy();
  expect(password, 'Set CUSTOMER_PASSWORD in .env').toBeTruthy();

  await page.setViewportSize({ width: 1365, height: 900 });
  await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(6000);

  await page.screenshot({
    path: 'test-results/customer-login-before.png',
  });

  // Coordinates match the login screenshot at 1365 × 900.
  await page.mouse.click(650, 386);
  await page.keyboard.insertText(email!);

  await page.mouse.click(650, 474);
  await page.keyboard.insertText(password!);

  await page.screenshot({
    path: 'test-results/customer-login-filled.png',
  });

  await page.mouse.click(680, 600);
  await page.waitForTimeout(8000);

  console.log('URL AFTER LOGIN:', page.url());
  console.log('TITLE AFTER LOGIN:', await page.title());

  await page.screenshot({
    path: 'test-results/customer-dashboard-discovery.png',
    fullPage: true,
  });

  // This checks application availability only, not authentication success.
  await expect(page).toHaveTitle('Ambulance First');
});
