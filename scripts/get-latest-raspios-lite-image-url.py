#!/usr/bin/env python3

import json
import urllib.request

url = "https://downloads.raspberrypi.com/os_list_imagingutility_v3.json"

with urllib.request.urlopen(url) as response:
    data = response.read()

json_str = data.decode("utf-8")
json_data = json.loads(json_str)

# Print the JSON data containing all Raspberry Pi OS images.
# See the official list of Raspberry Pi operating systems here:
# https://www.raspberrypi.com/software/operating-systems/
print(
    "Supported Devices:\n  - " + "\n  - ".join(json_data["os_list"][0]["devices"]), "\n"
)

# Get URL address for 'Raspberry Pi OS Lite (64-bit)'.
print(
    f"Latest Raspberry Pi OS Lite (64-bit) Image URL:\n  - {json_data['os_list'][3]['subitems'][0]['url']}"
)
