module.exports = {
  apps: [
    {
      name: "prompt-optimizer",
      script: "serve",
      args: "-s /home/syj88668/display/prompt-optimizer/current -l 3000 --single",
      env: {
        NODE_ENV: "production",
      },
    },
  ],
};
