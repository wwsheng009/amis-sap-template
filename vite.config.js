import { defineConfig, loadEnv } from "vite";

export default ({ mode }) => {
  process.env = { ...process.env, ...loadEnv(mode, process.cwd()) };

  // https://vitejs.dev/config/
  return defineConfig({
    root: "./app",
    base: "./",
    server: {
      host: "127.0.0.1",
      port: 8888, // 端口
      proxy: {
        "/sap": {
          target: "http://sapbp1809.e2yun.com:8080/", // 代理地址
          changeOrigin: true, // 是否允许跨域
          secure: false,
          configure: (proxy, options) => {
            // proxy will be an instance of 'http-proxy'
            const username = process.env.USERNAME;
            const password = process.env.PASSWORD;
            options.auth = `${username}:${password}`;
          },
        },
        "/fmcall": {
          // 请求接口中要替换的标识
          target: "http://sapbp1809.e2yun.com:8080/", // 代理地址
          changeOrigin: true, // 是否允许跨域
          secure: false,
          configure: (proxy, options) => {
            // proxy will be an instance of 'http-proxy'
            const username = process.env.USERNAME;
            const password = process.env.PASSWORD;
            options.auth = `${username}:${password}`;
          },
          // rewrite: (path) => path.replace(/^\/api/, ""), // api标志替换为''
        },
      },
    },
    plugins: [],
  });
};
