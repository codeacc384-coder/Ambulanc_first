import { test, expect } from '@playwright/test';

test('Ambulance First app loads successfully', async ({ page }) => {
  const errors: string[] = [];

  page.on('pageerror', error => {
    errors.push(error.message);
  });

  const response = await page.goto(
    'https://ambulance-first.saikamalnukala28.workers.dev/'
  );

  expect(response).not.toBeNull();
  expect(response!.status()).toBeLessThan(400);

  await expect(page.locator('body')).not.toBeEmpty();

  await page.screenshot({
    path: 'app-homepage.png',
    fullPage: true,
  });

  expect(errors).toEqual([]);
});