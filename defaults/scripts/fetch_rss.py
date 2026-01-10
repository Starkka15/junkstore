#!/usr/bin/env python3
"""
RSS Feed Fetcher for Junk Store
Fetches and parses RSS feeds with category filtering
"""

import sys
import json
import hashlib
import xml.etree.ElementTree as ET
from urllib.request import urlopen
from urllib.error import URLError, HTTPError


def fetch_rss_feed(url, excluded_categories=None, extensions=None):
 
    if excluded_categories is None:
        excluded_categories = ["Marketing", "Sponsored", "Promotion", "Sale"]
    if extensions is None:
        extensions = []

    try:
        from urllib.parse import urlencode, urlparse, parse_qs, urlunparse

        parsed = urlparse(url)
        query_params = parse_qs(parsed.query)
        query_params["base"] = ["decky"]

        if extensions:
            unique_sorted_extensions = sorted(list(set(extensions)))
            query_params["extensions"] = [",".join(unique_sorted_extensions)]

        new_query = urlencode(query_params, doseq=True)
        url = urlunparse(
            (
                parsed.scheme,
                parsed.netloc,
                parsed.path,
                parsed.params,
                new_query,
                parsed.fragment,
            )
        )

        with urlopen(url, timeout=10) as response:
            content = response.read().decode("utf-8")
        root = ET.fromstring(content)
        items = []
        namespaces = {
            "atom": "http://www.w3.org/2005/Atom",
            "content": "http://purl.org/rss/1.0/modules/content/",
        }
        for item in root.findall(".//item"):
            title = item.find("title")
            link = item.find("link")
            description = item.find("description")
            pub_date = item.find("pubDate")
            categories = []
            for category in item.findall("category"):
                if category.text:
                    categories.append(category.text)
            if any(cat in excluded_categories for cat in categories):
                continue
            item_title = title.text if title is not None else ""
            item_link = link.text if link is not None else ""
            item_id = hashlib.md5(f"{item_title}{item_link}".encode()).hexdigest()

            items.append(
                {
                    "id": item_id,
                    "title": item_title,
                    "link": item_link,
                    "description": description.text if description is not None else "",
                    "pubDate": pub_date.text if pub_date is not None else "",
                    "categories": categories,
                }
            )
        if not items:
            for entry in root.findall(".//atom:entry", namespaces):
                title = entry.find("atom:title", namespaces)
                link = entry.find("atom:link", namespaces)
                summary = entry.find("atom:summary", namespaces)
                published = entry.find("atom:published", namespaces)
                categories = []
                for category in entry.findall("atom:category", namespaces):
                    term = category.get("term")
                    if term:
                        categories.append(term)
                if any(cat in excluded_categories for cat in categories):
                    continue
                item_title = title.text if title is not None else ""
                item_link = link.get("href") if link is not None else ""
                item_id = hashlib.md5(f"{item_title}{item_link}".encode()).hexdigest()

                items.append(
                    {
                        "id": item_id,
                        "title": item_title,
                        "link": item_link,
                        "description": summary.text if summary is not None else "",
                        "pubDate": published.text if published is not None else "",
                        "categories": categories,
                    }
                )

        return {"items": items}

    except (URLError, HTTPError) as e:
        return {"error": f"Failed to fetch RSS feed: {str(e)}", "items": []}
    except ET.ParseError as e:
        return {"error": f"Failed to parse RSS feed: {str(e)}", "items": []}
    except Exception as e:
        return {"error": f"Unexpected error: {str(e)}", "items": []}


if __name__ == "__main__":
    try:
        input_data = sys.stdin.read()
        if input_data:
            args = json.loads(input_data)
            url = args.get("url", "https://www.junkstore.xyz/feed.xml")
            excluded_categories = args.get("excluded_categories", [])
            extensions = args.get("extensions", [])
        else:
            url = "https://www.junkstore.xyz/feed.xml"
            excluded_categories = []
            extensions = []

        result = fetch_rss_feed(url, excluded_categories, extensions)
        print(json.dumps(result))

    except Exception as e:
        print(json.dumps({"error": str(e), "items": []}))
        sys.exit(1)
