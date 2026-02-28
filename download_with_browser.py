#!/usr/bin/env python3
"""Download a URL using Playwright to bypass Cloudflare anti-bot protection.

Usage: python3 download_with_browser.py <url> <output_file>

Exits 0 on success, 1 on failure (prints error to stderr).
"""
import sys
import os


def main(url: str, output: str) -> None:
    from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=True,
            args=["--no-sandbox", "--disable-setuid-sandbox"],
        )
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/131.0.0.0 Safari/537.36"
            ),
            extra_http_headers={
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
                "Accept-Encoding": "gzip, deflate, br",
            },
        )
        page = context.new_page()

        try:
            page.goto(url, wait_until="networkidle", timeout=60000)
        except PlaywrightTimeoutError:
            # Still try to read the page even if networkidle timed out
            pass

        # If Cloudflare challenge is still active, wait a few extra seconds
        if "Just a moment" in page.title():
            try:
                page.wait_for_function(
                    "document.title !== 'Just a moment...'",
                    timeout=15000,
                )
            except PlaywrightTimeoutError:
                pass

        if "Just a moment" in page.title():
            print(
                f"ERROR: Cloudflare challenge was not resolved for {url}",
                file=sys.stderr,
            )
            browser.close()
            sys.exit(1)

        # For plain-text files the browser renders the content as body text.
        content = page.inner_text("body")

        if not content.strip():
            print(f"ERROR: Empty response for {url}", file=sys.stderr)
            browser.close()
            sys.exit(1)

        parent = os.path.dirname(os.path.abspath(output))
        os.makedirs(parent, exist_ok=True)
        with open(output, "w", encoding="utf-8") as f:
            f.write(content)

        browser.close()


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <url> <output_file>", file=sys.stderr)
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
