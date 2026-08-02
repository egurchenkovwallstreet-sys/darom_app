/** PM2 cluster: 2 процесса Node на 2 ядра CPU (Cloud MSK 50). */
module.exports = {
  apps: [
    {
      name: 'darom-api',
      script: 'src/index.js',
      cwd: '/opt/darom_app/backend',
      instances: 2,
      exec_mode: 'cluster',
      autorestart: true,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
      },
    },
  ],
};
