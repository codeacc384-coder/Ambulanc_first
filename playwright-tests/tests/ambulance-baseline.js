
import http from 'k6/http';
import { check, sleep } from 'k6';

const baseUrl = __ENV.BASE_URL;

if (!baseUrl) {
  throw new Error('Set BASE_URL before running this test');
}

export const options = {
  scenarios: {
    baseline: {
      executor: 'constant-vus',
      vus: 5,
      duration: '20s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1500'],
  },
};

export default function () {
  const response = http.get(baseUrl);

  check(response, {
    'homepage returns success': r => r.status >= 200 && r.status < 300,
    'homepage has a response body': r => r.body !== null && r.body.length > 0,
  });

  sleep(1);
}
