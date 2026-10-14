
import { test } from '@playwright/test';
import 'dotenv/config';

const APP_URL =
  (globalThis as typeof globalThis & {
    process: { env: Record<string, string | undefined> };
  }).process.env.BASE_URL ??
  'https://ambulance-first.saikamalnukala28.workers.dev/';

test('Diagnose blank Flutter screen', async ({ page }, testInfo) => {
  test.setTimeout(90000);

  await page.setViewportSize({ width: 1365, height: 900 });

  page.on('pageerror', error => {
    console.log('PAGE ERROR:', error.message);
  });

  page.on('console', message => {
    if (message.type() === 'error') {
      console.log('CONSOLE ERROR:', message.text());
    }
  });

  page.on('requestfailed', request => {
    console.log(
      'REQUEST FAILED:',
      request.method(),
      request.url(),
      request.failure()?.errorText
    );
  });

  page.on('response', response => {
    const url = response.url();

    if (
      /main\.dart\.js|flutter_bootstrap\.js|canvaskit|supabase/i.test(url)
    ) {
      console.log('RESOURCE:', response.status(), url);
    }
  });

  await page.goto(APP_URL, { waitUntil: 'domcontentloaded' });

  for (const [name, delay] of [
    ['01-after-2s', 2000],
    ['02-after-8s', 8000],
    ['03-after-15s', 15000],
  ] as const) {
    await page.waitForTimeout(delay);

    await testInfo.attach(name, {
      body: await page.screenshot({ fullPage: true }),
      contentType: 'image/png',
    });

    console.log(name, {
      url: page.url(),
      title: await page.title(),
      readyState: await page.evaluate(() => document.readyState),
      bodyText: await page.locator('body').innerText().catch(() => ''),
      flutterViews: await page.locator('flt-glass-pane').count(),
      canvases: await page.locator('canvas').count(),
    });
  }
});
