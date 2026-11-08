# 服务器定时部署

每天北京时间 00:00 拉取 GitHub `master`，执行 `npm ci` 和 `npm run build`，即使没有新提交也重新构建。服务器关机错过的任务不会补跑。

部署脚本安装至 `/usr/local/sbin/personal-blog-deploy`，service/timer 安装至 `/etc/systemd/system/`。构建使用专用用户 `blog-deploy`、目录 `/opt/personal-blog/source` 和 Node.js 22（`/opt/blog-node`）。

```bash
# 手动构建部署（后台运行）
systemctl start --no-block personal-blog-deploy.service

# 查看实时日志（Ctrl+C 只退出日志，不会停止构建）
journalctl -u personal-blog-deploy.service -f

# 查看最近构建结果、下次执行时间
systemctl status personal-blog-deploy.service
systemctl list-timers personal-blog-deploy.timer

# 暂停 / 恢复定时任务
systemctl disable --now personal-blog-deploy.timer
systemctl enable --now personal-blog-deploy.timer
```

构建失败不会发布，成功后原子切换 `/home/dist-test` 至新版本；保留最近三个版本及首次接管前的网站备份 `/home/personal-blog-original-*`。手动和定时执行共用并发锁。

脚本仅拉取已推送的代码，不会上传本地工作区修改。不要在服务器构建专用 checkout 内修改业务文件。

GitHub Actions 若仍启用，也会向网站目录发布；迁移后应在 GitHub 仓库 Actions 中停用原 `Deploy to Server` workflow，避免两个部署入口相互覆盖。
