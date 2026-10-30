#!/usr/bin/env python3
"""Writes the Sparkle appcast for one release of the fork.

Usage: appcast.py <version> <build> <archive url> <sign_update output> <release notes> <output>

Each release carries its own appcast, and the app reads the one of the latest release
(releases/latest/download/appcast.xml), so the feed only needs the newest item.
"""
import html
import re
import sys
from email.utils import formatdate

version, build, url, signature_output, notes, output = sys.argv[1:7]

# sign_update prints: sparkle:edSignature="..." length="..."
attributes = dict(re.findall(r'(sparkle:edSignature|length)="([^"]+)"', signature_output))
if set(attributes) != {"sparkle:edSignature", "length"}:
    sys.exit(f"Unexpected sign_update output: {signature_output!r}")

notes = "\n".join(line for line in notes.splitlines() if not line.startswith("Co-Authored-By:"))
lines = notes.strip().splitlines()
description = "<p>" + "<br>".join(html.escape(line) for line in lines) + "</p>"

appcast = f"""<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Maccy (KayakCbun fork)</title>
    <item>
      <title>{html.escape(version)}</title>
      <description><![CDATA[{description}]]></description>
      <pubDate>{formatdate(usegmt=True)}</pubDate>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url="{html.escape(url)}"
        sparkle:version="{html.escape(build)}"
        sparkle:shortVersionString="{html.escape(version)}"
        sparkle:edSignature="{attributes['sparkle:edSignature']}"
        length="{attributes['length']}"
        type="application/octet-stream"
      />
    </item>
  </channel>
</rss>
"""

with open(output, "w", encoding="utf-8") as file:
    file.write(appcast)
