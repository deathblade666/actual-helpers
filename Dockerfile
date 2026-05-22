# Use an official Node.js runtime as a parent image
FROM node:22

RUN apt-get update -qq -y && \
    apt-get install -y \
        libasound2 \
        libatk-bridge2.0-0 \
        libgtk-4-1 \
        libnss3 \
        xdg-utils \
        wget && \
    wget -q -O chrome-linux64.zip https://storage.googleapis.com/chrome-for-testing-public/131.0.6778.204/linux64/chrome-linux64.zip && \
    unzip chrome-linux64.zip && \
    rm chrome-linux64.zip && \
    mv chrome-linux64 /opt/chrome/ && \
    ln -s /opt/chrome/chrome /usr/local/bin/ && \
    wget -q -O chromedriver-linux64.zip https://storage.googleapis.com/chrome-for-testing-public/131.0.6778.204/linux64/chromedriver-linux64.zip && \
    unzip -j chromedriver-linux64.zip chromedriver-linux64/chromedriver && \
    rm chromedriver-linux64.zip && \
    mv chromedriver /usr/local/bin/

# Don't run as root
USER node

# Set the working directory in the container
WORKDIR /usr/src/app

# Create the cache directory
RUN mkdir -p ./cache && chown node:node ./cache

# Define environment variables
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

VOLUME ./cache

# Copy your helper scripts
COPY --chown=node:node . .

# Copy the built Actual API from workflow
COPY --chown=node:node actual-build/dist /usr/src/app/actual-api

# Install helper dependencies
RUN npm install && npm update
