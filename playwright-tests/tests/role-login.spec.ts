
import { test, expect, Page } from '@playwright/test';
import 'dotenv/config';

const APP_URL =
  (globalThis as typeof globalThis & {
    process?: { env?: Record<string, string | undefined> };
  }).process?.env?.BASE_URL ||
  'https://ambulance-first.saikamalnukala28.workers.dev/';

type RoleAccount = {
  role: string;
  emailEnv: string;
  passwordEnv: string;
};

const accounts = [
  {
    role: 'Customer',
    emailEnv: 'CUSTOMER_EMAIL',
    passwordEnv: 'CUSTOMER_PASSWORD',
  },
  {
    role: 'Customer Care',
    emailEnv: 'CUSTOMER_CARE_EMAIL',
    passwordEnv: 'CUSTOMER_CARE_PASSWORD',
  },
  {
    role: 'Driver',
    emailEnv: 'DRIVER_EMAIL',
    passwordEnv: 'DRIVER_PASSWORD',
  },
  {
    role: 'Team Lead',
    emailEnv: 'TEAM_LEAD_EMAIL',
    passwordEnv: 'TEAM_LEAD_PASSWORD',
  },
  {
    role: 'Admin',
    emailEnv: 'ADMIN_EMAIL',
    passwordEnv: 'ADMIN_PASSWORD',
  },

];

async function openLogin(page: Page) {
  await page.setViewportSize({
    width: 1326,
    height: 700,
  });

  const response = await page.goto(APP_URL, {
    waitUntil: 'domcontentloaded',
    timeout: 45000,
  });

  expect(response, 'The app should return a response').not.toBeNull();
  expect(response!.status()).toBeLessThan(400);

  await expect(page).toHaveTitle('Ambulance First');
  await page.waitForTimeout(3000);
}

async function enterCredentials(
  page: Page,
  email: string,
  password: string,
) {
  // Coordinates are based on the verified login screenshot
  // at a 1326 x 700 viewport.
  await page.mouse.click(620, 386);
  await page.keyboard.type(email);

  await page.mouse.click(620, 475);
  await page.keyboard.type(password);

  await page.screenshot({
    path: `test-results/login-filled.png`,
    fullPage: false,
  });

  await page.mouse.click(660, 600);
  await page.waitForTimeout(5000);
}

for (const account of accounts) {
  const env = (globalThis as typeof globalThis & {
    process?: { env?: Record<string, string | undefined> };
  }).process?.env;

  test(`Inspect ${account.role} login`, async ({ page }) => {
    test.setTimeout(60000);

    const email = env?.[account.emailEnv];
    const password = env?.[account.passwordEnv];

    test.skip(
      !email || !password,
      `Set ${account.emailEnv} and ${account.passwordEnv} before running this test.`,
    );

    await openLogin(page);

    await enterCredentials(page, email!, password!);

    console.log(`ROLE: ${account.role}`);
    console.log(`URL AFTER SUBMIT: ${page.url()}`);
    console.log(`TITLE AFTER SUBMIT: ${await page.title()}`);

    // Diagnostic screenshot: the next step is to verify the
    // actual dashboard or authentication error for each role.
    await page.screenshot({
      path: `test-results/${account.role
        .toLowerCase()
        .replace(/\s+/g, '-')}-after-login.png`,
      fullPage: true,
    });

    expect(await page.title()).toBe('Ambulance First');
  });
}
