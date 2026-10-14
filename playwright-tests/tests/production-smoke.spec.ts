
import { test, expect } from '@playwright/test';
import 'dotenv/config';

declare const process: {
  env: Record<string, string | undefined>;
};

const baseUrl =
  process.env.BASE_URL ??
  'https://ambulance-first.saikamalnukala28.workers.dev/';

test('production site responds and loads Flutter assets', async ({ page }) => {
  test.setTimeout(90_000);

  const pageErrors: string[] = [];
  const failedRequests: string[] = [];

  page.on('pageerror', error => pageErrors.push(error.message));

  page.on('requestfailed', request => {
    failedRequests.push(
      `${request.method()} ${request.url()}`
    );
  });

  const response = await page.goto(baseUrl, {
    waitUntil: 'domcontentloaded',
    timeout: 45_000,
  });

  expect(response, 'Main document should respond').not.toBeNull();
  expect(response!.status()).toBeLessThan(400);

  await page.waitForTimeout(10_000);

  const flutterState = await page.evaluate(() => ({
    title: document.title,
    readyState: document.readyState,
    flutterHostCount: document.querySelectorAll('flt-glass-pane').length,
    canvasCount: document.querySelectorAll('canvas').length,
    bodyText: document.body?.innerText ?? '',
  }));

  await page.screenshot({
    path: 'test-results/production-smoke.png',
    fullPage: true,
  });

  console.log('Flutter state:', flutterState);
  console.log('Browser errors:', pageErrors);
  console.log('Failed requests:', failedRequests);

  expect(flutterState.readyState).toBe('complete');
  expect(flutterState.flutterHostCount + flutterState.canvasCount)
    .toBeGreaterThan(0);

  expect(pageErrors, 'No uncaught browser errors').toEqual([]);
});
