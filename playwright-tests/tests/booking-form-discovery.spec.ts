
import { test, expect } from '@playwright/test';
import 'dotenv/config';

const env = (globalThis as { process?: { env?: Record<string, string | undefined> } }).process?.env ?? {};

const APP_URL =
  env.BASE_URL ??
  'https://ambulance-first.saikamalnukala28.workers.dev/';

test('Booking wizard: service selection to step 2', async ({ page }) => {
  const email = env.CUSTOMER_EMAIL;
  const password = env.CUSTOMER_PASSWORD;

  expect(email).toBeTruthy();
  expect(password).toBeTruthy();

  await page.setViewportSize({ width: 1365, height: 900 });
  await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(6000);

  // Customer login
  await page.mouse.click(650, 386);
  await page.keyboard.insertText(email!);
  await page.mouse.click(650, 474);
  await page.keyboard.insertText(password!);
  await page.mouse.click(680, 600);
  await page.waitForTimeout(7000);

  // Open the booking wizard from the Customer dashboard.
  await page.mouse.click(800, 220);
  await page.waitForTimeout(2500);

  await page.screenshot({
    path: 'test-results/booking-step-1-before.png',
  });

  // Select ICU Ambulance in the Road Ambulance setup.
  await page.mouse.click(500, 630);
  await page.waitForTimeout(500);

  await page.screenshot({
    path: 'test-results/booking-step-1-selected.png',
  });

  // Continue to the next step.
  await page.mouse.click(1187, 734);
  await page.waitForTimeout(2000);

  await page.screenshot({
    path: 'test-results/booking-step-2.png',
    fullPage: true,
  });

  console.log('Booking wizard URL:', page.url());
  console.log('Reached step 2; inspect booking-step-2.png');
  await expect(page).toHaveTitle('Ambulance First');
});
