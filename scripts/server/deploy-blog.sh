#!/usr/bin/env bash
set -Eeuo pipefail
export PATH=/opt/blog-node/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export TZ=Asia/Shanghai
exec 9>/run/lock/personal-blog-deploy.lock
flock -n 9 || { echo 'Another deployment is running.'; exit 0; }
trap 'echo "Deployment failed at line $LINENO; current site retained."' ERR
echo "[$(date --iso-8601=seconds)] Starting deployment"

# Build with an unprivileged account in an isolated checkout.
runuser -u blog-deploy -- env PATH="$PATH" HOME=/opt/personal-blog bash <<'BUILD'
set -Eeuo pipefail
export GIT_TERMINAL_PROMPT=0
cd /opt/personal-blog
if [[ ! -d source/.git ]]; then
  git clone --branch master --single-branch https://github.com/lrsm21427/Personal-Blog.git source
fi
cd source
[[ -z "$(git status --porcelain --untracked-files=no)" ]] || { echo 'Checkout has local changes; aborting.'; exit 1; }
git fetch --prune origin master
git merge --ff-only origin/master
# Build every invocation, even when the commit has not changed.
npm ci --no-audit --no-fund
npm run build
test -s .vitepress/dist/index.html
BUILD

release="/home/personal-blog-releases/$(date +%Y%m%d-%H%M%S)-$$"
install -d -m 755 "$release"
cp -a /opt/personal-blog/source/.vitepress/dist/. "$release/"
chown -R root:root "$release"
chmod -R a+rX "$release"

# Atomic exchange also handles the first deployment's existing real directory.
python3 - "$release" <<'PUBLISH'
import ctypes
import os
from pathlib import Path
import shutil
import sys

release = Path(sys.argv[1])
live = Path('/home/dist-test')
link = Path('/home/.personal-blog-next')
if link.exists() or link.is_symlink():
    raise RuntimeError('Unexpected pending publish path; inspect /home/.personal-blog-next')
link.symlink_to(release, target_is_directory=True)
try:
    if live.is_dir() and not live.is_symlink():
        libc = ctypes.CDLL(None, use_errno=True)
        if libc.renameat2(-100, os.fsencode(link), -100, os.fsencode(live), 2) != 0:
            raise OSError(ctypes.get_errno(), 'Atomic directory exchange failed')
        # Preserve the pre-automation website as a separate backup.
        link.rename('/home/personal-blog-original-' + release.name)
    else:
        os.replace(link, live)
finally:
    if link.is_symlink():
        link.unlink()
print('Published:', release)

# Keep the latest three releases; never remove the live target.
releases = sorted(release.parent.iterdir(), key=lambda p: p.name, reverse=True)
for old in releases[3:]:
    if old.is_dir() and not old.is_symlink() and old.resolve() != live.resolve():
        shutil.rmtree(old)
PUBLISH
echo "[$(date --iso-8601=seconds)] Deployment complete"
