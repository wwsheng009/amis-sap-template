import { defineConfig, loadEnv } from "vite";

export default ({ mode }) => {
  process.env = { ...process.env, ...loadEnv(mode, process.cwd()) };
  const username = process.env.VITE_SAP_USER;
  const password = process.env.VITE_SAP_PASS;
  // https://vitejs.dev/config/
  return defineConfig({
    root: "./app",
    base: "./",
    server: {
      host: "localhost",
      port: 9999, // 端口
      proxy: {
        "/sap": {
          target: "http://sapbp1809.e2yun.com:8080/", // 代理地址
          changeOrigin: true, // 是否允许跨域
          secure: false,
          auth: `${username}:${password}`,
          // configure: (proxy, options) => {
          //   console.log("process.env", process.env);
          //   // proxy will be an instance of 'http-proxy'
          //   const username = process.env.SAP_USER;
          //   const password = process.env.SAP_PASS;
          //   options.auth = `${username}:${password}`;
          // },
        },
        "/amis": {
          // 请求接口中要替换的标识
          target: "http://sapbp1809.e2yun.com:8080/", // 代理地址
          changeOrigin: true, // 是否允许跨域
          secure: false,
          auth: `${username}:${password}`,
          // configure: (proxy, options) => {
          //   console.log("process.env", process.env);
          //   // proxy will be an instance of 'http-proxy'
          //   const username = process.env.SAP_USER;
          //   const password = process.env.SAP_PASS;
          //   options.auth = `${username}:${password}`;
          // },
          // rewrite: (path) => path.replace(/^\/api/, ""), // api标志替换为''
        },
      },
    },
    plugins: [],
  });
};
