
import { test } from '@playwright/test';

const deployments = [
  {
    name: 'ambulance-first',
    url: 'https://ambulance-first.saikamalnukala28.workers.dev/',
  },
  {
    name: 'ambulance-first2',
    url: 'https://ambulance-first.saikamalnukala28.workers.dev/',
  },
];

for (const deployment of deployments) {
  test(`Inspect ${deployment.name} deployment`, async ({ page }) => {
    test.setTimeout(60000);

    const errors: string[] = [];

    page.on('pageerror', error => {
      errors.push(error.message);
    });

    const response = await page.goto(deployment.url, {
      waitUntil: 'domcontentloaded',
      timeout: 30000,
    });

    await page.waitForTimeout(8000);

    const result = await page.evaluate(() => {
      const pane = document.querySelector('flt-glass-pane');
      const rect = pane?.getBoundingClientRect();

      return {
        title: document.title,
        url: location.href,
        paneWidth: rect?.width ?? 0,
        paneHeight: rect?.height ?? 0,
        canvasCount: document.querySelectorAll('canvas').length,
        bodyText: document.body.innerText.slice(0, 500),
      };
    });

    console.log(`DEPLOYMENT: ${deployment.name}`);
    console.log('HTTP STATUS:', response?.status());
    console.log('UI RESULT:', JSON.stringify(result, null, 2));
    console.log('PAGE ERRORS:', JSON.stringify(errors));

    await page.screenshot({
      path: `test-results/${deployment.name}-comparison.png`,
      fullPage: true,
    });
  });
}
