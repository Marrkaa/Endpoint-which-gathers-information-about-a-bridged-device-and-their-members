# Lua network API endpoints

This project adds some custom API endpoints which expose information about
network bridge devices, routing tables and DHCP leases.

## First endpoint - bridge devices and their members

The first endpoint gathers detailed information about bridge devices on the router, such as the br-lan device, and the interfaces connected to it (members). This is achieved by utilizing the ubus protocol to query the network status of the device. The data collected includes the bridge's name, type, MAC address, and its members (other interfaces that are part of the bridge). The endpoint ensures that only devices with the type bridge are considered, and for each such device, it gathers its associated member interfaces. It retrieves additional information like the device status (up), carrier status, and MAC addresses of those member interfaces. If no bridge devices are found, the endpoint responds with an error. The final result is a structured response containing the bridge device information, which can be used for further network configuration or monitoring.

## Second endpoint - setting the parameters of a bridge device

The second endpoint allows the modification of the parameters for a bridge device, such as its MTU, MAC address, and device name. This endpoint first checks the provided data and ensures that the necessary parameters, such as the bridge name, are valid. Then, it uses the UCI system to apply changes to the network configuration. Changes like adjusting the MTU, updating the MAC address, and renaming the device are made through UCI. The endpoint also ensures that the network configuration is committed and reloaded to apply the changes effectively. If any of the parameters are invalid or if the bridge does not exist, appropriate error messages are returned. Once the changes are successfully applied, the endpoint responds with a confirmation message, indicating that the bridge configuration has been updated.

## Third endpoint

The third endpoint focuses on gathering information about the active routing tables on the router. This is done using the ```ip -json route show table all``` command, which is executed through Lua’s io.popen to collect all the current routing entries. The endpoint parses the results, which are returned in JSON format, and organizes them by the specific routing tables. If no routing table is specified in the entry, the endpoint assigns it to the default main table. The results include details about each route, such as the associated device (dev), protocol, destination (dst), source (prefsrc), scope, and flags. The endpoint then returns a structured response containing the routes sorted by their respective tables.

## Fourth endpoint

The final endpoint retrieves information about the DHCP clients connected to the router. It uses the ubus protocol with the dnsmasq service to gather active DHCP leases. The DHCP leases include details such as the MAC address, IP address, and the hostname of each connected device. If there are no active DHCP leases or if the connection to the ubus object fails, an error message is returned.