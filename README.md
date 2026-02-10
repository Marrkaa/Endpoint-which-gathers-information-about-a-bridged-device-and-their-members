# Bridge Device API

This project adds a custom REST API endpoint that exposes information about
network bridge devices (currently `br-lan`) using `ubus`.

## Overview

The API is a lightweight wrapper around the system command:
```
ubus call network.device status
```
It retrieves bridge-related data from `ubus` and exposes it over HTTP
in JSON format for use by external clients or WebUI components.
