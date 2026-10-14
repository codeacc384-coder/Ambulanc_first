
import { test, expect } from '@playwright/test';
import 'dotenv/config';

declare const process: {
  env: {
    BASE_URL?: string;
  };
};

const APP_URL =
  process.env.BASE_URL ??
  'https://ambulance-first.saikamalnukala28.workers.dev/';

test('Analyze the booking workflow', async ({ page }) => {
  const failures: string[] = [];
  const consoleErrors: string[] = [];
  const apiFailures: string[] = [];
  const timeline: Array<Record<string, unknown>> = [];

  page.on('pageerror', error => {
    consoleErrors.push(error.message);
  });

  page.on('requestfailed', request => {
    apiFailures.push(
      `${request.method()} ${request.url()} — ` +
      `${request.failure()?.errorText ?? 'Request failed'}`
    );
  });

  async function checkpoint(stage: string) {
    const entry = {
      stage,
      url: page.url(),
      timestamp: new Date().toISOString(),
    };

    timeline.push(entry);

    await page.screenshot({
      path: `test-results/booking-${stage
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')}.png`,
      fullPage: true,
    });
  }

  await page.goto(APP_URL, {
    waitUntil: 'domcontentloaded',
  });

  await page.waitForTimeout(5000);
  await checkpoint('application-start');

  // TODO: Sign in as Customer using the existing test helper.
  // TODO: Create a test booking with unique test data.
  // TODO: Capture the booking ID and initial status.
  // TODO: Sign in as Customer Care and verify the booking.
  // TODO: Confirm the handoff to Team Lead.
  // TODO: Create and accept a quotation.
  // TODO: Allocate an eligible driver/ambulance.
  // TODO: Sign in as Driver and progress the assigned booking.
  // TODO: Verify final status and booking history.

  console.log('WORKFLOW TIMELINE:', JSON.stringify(timeline, null, 2));
  console.log('CONSOLE ERRORS:', JSON.stringify(consoleErrors, null, 2));
  console.log('FAILED REQUESTS:', JSON.stringify(apiFailures, null, 2));
  console.log('WORKFLOW FAILURES:', JSON.stringify(failures, null, 2));

  expect(consoleErrors, 'Browser runtime errors').toEqual([]);
});
