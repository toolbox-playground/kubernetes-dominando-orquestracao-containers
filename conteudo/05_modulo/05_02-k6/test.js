import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '10s', target: 10 }, // Aumenta para 10 usuários em 10s
    { duration: '30s', target: 50 }, // Mantém 50 usuários por 30s
    { duration: '10s', target: 2500 }, // Mantém 50 usuários por 30s
    { duration: '10s', target: 2500 }, // Mantém 50 usuários por 30s
    { duration: '10s', target: 0 },  // Reduz para 0 usuários em 10s
  ],
};

export default function () {
  let res = http.get('http://localhost:3000/home');

  check(res, {
    'status é 200': (r) => r.status === 200,
    'resposta contém "Test!"': (r) => r.body.includes("Test!"),
  });

  sleep(1); // Espera 1 segundo antes da próxima iteração
}
