# Amis 与 SAP NetWeaver 集成

## 1. 简介

## 2. 功能

在 SAP 中使用 Amis 集成 SAP 的功能。

## 3. 架构

使用 AMIS JSSDK 与 SAP NetWeaver 集成。

## 4. 部署

上传 AMIS SDK 到 SAP 服务器中的 MIME 库。

### 上传 SDK

这一步需要在 SAP 服务器中配置 MIME 库。在 SAP 服务器中使用程序 ZAMIS_UPLOAD_LIBRARY，上传 AMIS SDK 到 SAP 服务器中的 MIME 库。

默认会上传到这个路径：/sap/public/bc/ur/amis/。

上传完后可通过以下路径访问 js 文件，/sap/public/bc/ur/amis/sdk.js

### 上传 EDITOR 到 SAP

在 SAP 中使用程序 程序 ZAMIS_BSP_REPOSITORY_LOAD 上传编辑器应用到 SAP。

编译 editor 应用。

下载 amis 编辑器应用。

```sh
git clone https://github.com/aisuda/amis-editor-demo.git

cd amis-editor-demo

npm install

```

修改 editor 的编译配置文件 amis.config.js，找到以下配置并修改。

```sh
assetsRoot: resolve('./zamis_editor'), // 打包后的文件绝对路径（物理路径）
assetsPublicPath: '/sap/bc/ui5_ui5/sap/zamis_editor/', // 设置静态资源的引用路径（根域名+路径）
```

编译 editor 应用并上传到 SAP。

```sh
npm run build
```

在 SAP 中执行程序 ZAMIS_BSP_REPOSITORY_LOAD 上传 editor 应用到 SAP 服务器。应用名称一定要是 zamis_editor。

### 上传测试应用到 SAP

在 SAP 中使用程序 ZAMIS_BSP_REPOSITORY_LOAD 上传应用到 SAP 服务器。

ZAMIS_BSP_REPOSITORY_LOAD 会自动加载应用到 SAP 服务器。

应用是目录下的 app 目录。

不使用程序 UI5_REPOSITORY_LOAD 的原因是 UI5_REPOSITORY_LOAD 会忽略一些字体文件。

## 5. 配置

### 5.1 配置 SAP 服务器

启用 SICF 配置。

应用域名。

### 5.2 配置 Amis

### 5.3 配置 Amis 与 SAP 服务器的连接

在开发阶段通过 vite 的代理功能，可以将请求转发到 SAP 服务器。

在.env 文件中配置 SAP 服务连接的用户密码。

在 vite.config.js 中配置服务器的地址

## 6. 运行

在开发阶段，开启 vite 服务器。

```sh
npm run dev
```

在 SAP 中可以`/sap/bc/ui5_ui5/sap/`路径中找到应用的访问地址。比如应用名称是 zamis_demo_01，它的访问地址是：`/sap/bc/ui5_ui5/sap/zamis_demo_01`
