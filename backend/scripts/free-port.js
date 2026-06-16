const { execSync } = require('child_process');

const port = String(process.env.PORT || 3000);

function freePort() {
  try {
    const output = execSync(`netstat -ano | findstr :${port}`, { encoding: 'utf8' });
    const pids = new Set();

    for (const line of output.split('\n')) {
      if (!line.includes('LISTENING')) continue;
      const pid = line.trim().split(/\s+/).pop();
      if (pid && pid !== '0') pids.add(pid);
    }

    for (const pid of pids) {
      try {
        execSync(`taskkill /PID ${pid} /F`, { stdio: 'ignore' });
        console.log(`Освобождён порт ${port}: остановлен процесс ${pid}`);
      } catch {
        // процесс уже завершился
      }
    }
  } catch {
    // порт свободен
  }
}

freePort();
