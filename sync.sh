#!/bin/bash
mkdir -p rules
URLS=(
  "https://yfamilys.com/rule/ai.list"
  "https://yfamilys.com/rule/Microsoft.list"
  "https://yfamilys.com/rule/Apple.list"
  "https://yfamilys.com/rule/AppStore.list"
  "https://yfamilys.com/rule/AppleProxy.list"
  "https://yfamilys.com/rule/Telegram.list"
  "https://yfamilys.com/rule/Weibo.list"
  "https://yfamilys.com/rule/WeChat.list"
  "https://yfamilys.com/rule/Twitter.list"
  "https://yfamilys.com/rule/PlayStation.list"
  "https://yfamilys.com/rule/Epic.list"
  "https://yfamilys.com/rule/Sony.list"
  "https://yfamilys.com/rule/Steam.list"
  "https://yfamilys.com/rule/Nintendo.list"
  "https://yfamilys.com/rule/WanMeiShiJie.list"
  "https://yfamilys.com/rule/Blizzard.list"
  "https://yfamilys.com/rule/Spotify.list"
  "https://yfamilys.com/rule/PayPal.list"
  "https://yfamilys.com/rule/Facebook.list"
  "https://yfamilys.com/rule/Reddit.list"
  "https://yfamilys.com/rule/Discord.list"
  "https://yfamilys.com/rule/YouTube.list"
  "https://yfamilys.com/rule/YouTubeMusic.list"
  "https://yfamilys.com/rule/Netflix.list"
  "https://yfamilys.com/rule/Disney.list"
  "https://yfamilys.com/rule/BiliBili.list"
  "https://yfamilys.com/rule/ChinaMedia.list"
  "https://yfamilys.com/rule/ProxyMedia.list"
  "https://yfamilys.com/rule/Twitch.list"
  "https://yfamilys.com/rule/Douyu.list"
  "https://yfamilys.com/rule/Google.list"
  "https://yfamilys.com/rule/Proxy.list"
  "https://yfamilys.com/rule/ASN-CN.list"
)

for url in "${URLS[@]}"; do
  filename=$(basename "$url")
  echo "Downloading $filename..."
  curl -sSL -o "rules/$filename" "$url"
done
echo "Sync complete."