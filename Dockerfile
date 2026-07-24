FROM crazymax/flarum:latest

WORKDIR /opt/flarum

# ─────────────────────────────────────────────────────
# Pre-requisites: git for VCS composer repositories
# ─────────────────────────────────────────────────────
RUN apk add --no-cache git \
    && git config --global url."https://github.com/".insteadOf git@github.com:

# ─────────────────────────────────────────────────────
# Layer 1: Third-party Composer plugins (remote)
# ─────────────────────────────────────────────────────
RUN composer require \
    flarum-lang/chinese-simplified \
    flarum-lang/spanish \
    fof/analytics:* \
    fof/formatting \
    fof/photoswipe \
    darkle/fancybox \
    walsgit/flarum-discussion-cards \
    forumaker/magicbb

# ─────────────────────────────────────────────────────
# Layer 2: Plugin from GitHub fork (VCS repository)
# ─────────────────────────────────────────────────────
RUN composer config repositories.login2see vcs https://github.com/rainbowtrash2333/flarum-login2see \
    && composer require rainbowtrash2333/flarum-login2see:@dev

# ─────────────────────────────────────────────────────
# Layer 3: Local extensions (on-disk source)
# ─────────────────────────────────────────────────────
COPY extensions/translate_flarum/flarum-ext-translate /my-extensions/translate_flarum
RUN composer config repositories.twikura-translate path /my-extensions/translate_flarum \
    && composer require twikura/flarum-ext-translate:@dev

# ─────────────────────────────────────────────────────
# Layer 4: Build JS frontend assets
# ─────────────────────────────────────────────────────
RUN apk add --no-cache nodejs npm
WORKDIR /my-extensions/translate_flarum/js
RUN npm install
RUN npm run build
WORKDIR /opt/flarum

# ─────────────────────────────────────────────────────
# Cleanup: remove Composer cache to keep the image lean
# ─────────────────────────────────────────────────────
RUN rm -rf /tmp/* ~/.composer/cache
