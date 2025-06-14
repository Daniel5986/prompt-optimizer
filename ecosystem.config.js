module.exports = {
  apps: [
    {
      name: "prompt-optimizer",
      script: "serve",
      args: "-s packages/web/dist -l 3000 --single",
      env: {
        NODE_ENV: "production",
      },
    },
  ],
};
