
import { test, expect } from '@playwright/test';

test('Inspect Flutter startup resources', async ({ page }) => {
  test.setTimeout(60000);

  page.on('console', message => {
    if (message.type() === 'error') {
      console.log('CONSOLE ERROR:', message.text());
    }
  });

  page.on('requestfailed', request => {
    console.log(
      'REQUEST FAILED:',
      request.url(),
      request.failure()?.errorText
    );
  });

  page.on('response', response => {
    if (
      /main\.dart\.js|flutter_bootstrap\.js|flutter\.js|canvaskit/i
        .test(response.url())
    ) {
      console.log(
        'FLUTTER RESOURCE:',
        response.status(),
        response.url()
      );
    }
  });

  await page.goto(
    'https://ambulance-first.saikamalnukala28.workers.dev/',
    { waitUntil: 'domcontentloaded' }
  );

  await page.waitForTimeout(8000);

  const result = await page.evaluate(() => ({
    scripts: Array.from(document.scripts).map(script => ({
      src: script.src || '(inline)',
      type: script.type,
    })),
    flutterElements: Array.from(
      document.querySelectorAll('flt-glass-pane, flt-scene-host')
    ).map(element => ({
      tag: element.tagName,
      display: getComputedStyle(element).display,
      visibility: getComputedStyle(element).visibility,
      width: element.getBoundingClientRect().width,
      height: element.getBoundingClientRect().height,
    })),
    resourceFailures: performance.getEntriesByType('resource')
      .filter(entry =>
        /main\.dart\.js|flutter_bootstrap\.js|flutter\.js|canvaskit/i
          .test(entry.name)
      )
      .map(entry => ({
        name: entry.name,
        duration: entry.duration,
        transferSize: (entry as PerformanceResourceTiming).transferSize,
      })),
  }));

  console.log('FLUTTER STARTUP:', JSON.stringify(result, null, 2));

  await page.screenshot({
    path: 'test-results/flutter-startup.png',
    fullPage: true,
  });

  expect(result.scripts.length).toBeGreaterThan(0);
});
