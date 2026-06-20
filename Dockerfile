# ==========================================
# STAGE 1: Build & Package Actual Monorepo Workspace
# ==========================================
# Upgraded to node:22 to match Actual's modern dependencies and Stage 2
FROM node:22 AS builder
WORKDIR /app

# Install git so yarn can handle monorepo dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends git

COPY actual-src/ .

# Enable Corepack so the container respects Actual's configured Yarn 4 engine
RUN corepack enable

# 1. Install internal dependencies securely using modern Yarn immutable rules
# 2. Build the API bundle across the workspace topological graph
# 3. Navigate to the API folder and pack it into a clean tarball package (.tgz)
RUN yarn install --immutable && \
    yarn workspace @actual-app/api build && \
    cd packages/api && \
    yarn pack --filename actual-app-api.tgz

# ==========================================
# STAGE 2: Helper Runtime Container
# ==========================================
FROM node:22

# Install System Requirements for Playwright/Selenium & Chrome
RUN apt-get update -qq -y && \
    apt-get install -y --no-install-recommends \
        libasound2 \
        libatk-bridge2.0-0 \
        libgtk-4-1 \
        libnss3 \
        xdg-utils \
        unzip \
        wget && \
    wget -q -O chrome-linux64.zip https://storage.googleapis.com/chrome-for-testing-public/131.0.6778.204/linux64/chrome-linux64.zip && \
    unzip chrome-linux64.zip && \
    rm chrome-linux64.zip && \
    mv chrome-linux64 /opt/chrome/ && \
    ln -s /opt/chrome/chrome /usr/local/bin/ && \
    wget -q -O chromedriver-linux64.zip https://storage.googleapis.com/chrome-for-testing-public/131.0.6778.204/linux64/chromedriver-linux64.zip && \
    unzip -j chromedriver-linux64.zip chromedriver-linux64/chromedriver && \
    rm chromedriver-linux64.zip && \
    mv chromedriver /usr/local/bin/ && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# Pull down ONLY the compiled, production-ready tarball archive from Stage 1
COPY --from=builder /app/packages/api/actual-app-api.tgz /usr/src/app/

# Ensure application permissions are healthy
RUN mkdir -p ./cache && chown -R node:node /usr/src/app
USER node

# Environment Variables
ENV NODE_ENV=production
ENV ACTUAL_SERVER_URL=""
ENV ACTUAL_SERVER_PASSWORD=""
ENV ACTUAL_SYNC_ID=""
ENV NODE_TLS_REJECT_UNAUTHORIZED=0
ENV CHROMEDRIVER_SKIP_DOWNLOAD=true
ENV ACTUAL_FILE_PASSWORD=""
ENV ACTUAL_CACHE_DIR="./cache"
ENV INTEREST_PAYEE_NAME="Loan Interest"
ENV INVESTMENT_PAYEE_NAME="Investment"
ENV INVESTMENT_CATEGORY_GROUP_NAME="Income"
ENV INVESTMENT_CATEGORY_NAME="Investment"
ENV SIMPLEFIN_CREDENTIALS=""
ENV ZESTIMATE_PAYEE_NAME="Zestimate"
ENV KBB_PAYEE_NAME="KBB"
ENV BITCOIN_PRICE_URL="https://api.kraken.com/0/public/Ticker?pair=xbtusd"
ENV BITCOIN_PRICE_JSON_PATH="result.XXBTZUSD.c[0]"
ENV BITCOIN_PAYEE_NAME="Bitcoin Price Change"
ENV RENTCAST_API_KEY=""
ENV RENTCAST_PAYEE_NAME="RentCast"

VOLUME ["/usr/src/app/cache"]

# Copy helper scripts
COPY --chown=node:node . .

# Install helper dependencies
RUN npm install && npm update

ENTRYPOINT ["tail", "-f", "/dev/null"]
