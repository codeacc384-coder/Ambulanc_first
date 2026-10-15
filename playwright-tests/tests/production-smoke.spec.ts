
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

  page.on('pageerror', error => {
    pageErrors.push(error.message);
  });

  page.on('requestfailed', request => {
    failedRequests.push(`${request.method()} ${request.url()}`);
  });

  const response = await page.goto(baseUrl, {
    waitUntil: 'domcontentloaded',
    timeout: 45_000,
  });

  expect(response, 'Main document should respond').not.toBeNull();
  expect(response!.status()).toBeLessThan(400);

  // Wait for Flutter to initialize its rendering surface.
  await page.waitForFunction(
    () => {
      const canvas = document.querySelector('canvas');
      const pane = document.querySelector('flt-glass-pane');
      const view = document.querySelector('flutter-view');

      return Boolean(canvas || pane || view);
    },
    { timeout: 45_000 }
  );

  const flutterState = await page.evaluate(() => {
    const canvas = document.querySelector('canvas');
    const pane = document.querySelector('flt-glass-pane');
    const view = document.querySelector('flutter-view');

    return {
      title: document.title,
      readyState: document.readyState,
      flutterHostCount: document.querySelectorAll('flt-glass-pane').length,
      flutterViewCount: document.querySelectorAll('flutter-view').length,
      canvasCount: document.querySelectorAll('canvas').length,
      canvasWidth: canvas?.getBoundingClientRect().width ?? 0,
      canvasHeight: canvas?.getBoundingClientRect().height ?? 0,
      paneWidth: pane?.getBoundingClientRect().width ?? 0,
      paneHeight: pane?.getBoundingClientRect().height ?? 0,
      viewWidth: view?.getBoundingClientRect().width ?? 0,
      viewHeight: view?.getBoundingClientRect().height ?? 0,
      bodyText: document.body?.innerText ?? '',
    };
  });

  await page.screenshot({
    path: 'test-results/production-smoke.png',
    fullPage: true,
  });

  console.log('Flutter state:', flutterState);
  console.log('Browser errors:', pageErrors);
  console.log('Failed requests:', failedRequests);

  // Verify that a Flutter rendering surface exists.
  expect(
    flutterState.flutterHostCount +
      flutterState.flutterViewCount +
      flutterState.canvasCount,
    'Flutter rendering surface should exist'
  ).toBeGreaterThan(0);

  // Verify that the rendering surface has usable dimensions.
  expect(
    Math.max(
      flutterState.canvasWidth,
      flutterState.paneWidth,
      flutterState.viewWidth
    ),
    'Flutter rendering surface should have positive width'
  ).toBeGreaterThan(0);

  expect(
    Math.max(
      flutterState.canvasHeight,
      flutterState.paneHeight,
      flutterState.viewHeight
    ),
    'Flutter rendering surface should have positive height'
  ).toBeGreaterThan(0);

  expect(pageErrors, 'No uncaught browser errors').toEqual([]);
});