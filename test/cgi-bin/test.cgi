#!/usr/bin/python3
# To be run using /usr/bin/python3 -m http.server --cgi 8080

from datetime import datetime
from time import sleep

print("Content-type: text/html\n")
print(datetime.now())
sleep(2)
print(datetime.now())

