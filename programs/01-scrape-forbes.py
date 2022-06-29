# ---------------------------------------------------------------------------- #
# Import real-time Forbes data
# ---------------------------------------------------------------------------- #

import waybackpy
import datetime
import calendar
import urllib
import json
import pandas as pd
import sys
import time
import ssl

try:
    _create_unverified_https_context = ssl._create_unverified_context
except AttributeError:
    # Legacy Python that doesn't verify HTTPS certificates by default
    pass
else:
    # Handle target environment that doesn't support HTTPS verification
    ssl._create_default_https_context = _create_unverified_https_context

# Import data end of every month from 2020 onwards
dates = []
for year in range(2020, datetime.date.today().year + 1):
    for month in range(1, 13):
        last_day = calendar.monthrange(year, month)[1]
        if (datetime.date(year, month, last_day) < datetime.date.today()):
            dates.append((year, month, last_day))

# Scrap Forbes list closest to that day from the Wayback machine
user_agent = "Mozilla/5.0 (Windows NT 5.1; rv:40.0) Gecko/20100101 Firefox/40.0"
url = "https://www.forbes.com/forbesapi/person/rtb/0/position/true.json"
availability_api = waybackpy.WaybackMachineAvailabilityAPI(url, user_agent)

table_all = []
for date in dates:
    print(date)
    while True:
        try:
            archive_wayback = availability_api.near(year=date[0], month=date[1], day=date[2], hour=24)
            archive_url = archive_wayback.archive_url
            # Tweak URL to get raw JSON
            archive_url = archive_url[0:42] + "if_" + archive_url[42:len(archive_url)]
            response_wayback = urllib.request.urlopen(archive_url).read().decode()
            json_wayback = json.loads(response_wayback)
            # Download and flatten the table
            table_wayback = pd.json_normalize(json_wayback["personList"]["personsLists"])
            table_wayback["year"] = date[0]
            table_wayback["month"] = date[1]
        except Exception as e:
            print(e)
            print("error, retrying in 10s...")
            time.sleep(10)
        else:
            break
    table_all.append(table_wayback)

table_all = pd.concat(table_all)
table_all.to_csv(sys.argv[1])
