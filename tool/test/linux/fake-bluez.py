#!/usr/bin/env python3
# Stand-in for bluetoothd on the system bus: BlueZ without any adapter, like a
# desktop without Bluetooth hardware. The real bluetoothd can't run in the
# container (no Bluetooth management socket outside the host's namespace).
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib


class Root(dbus.service.Object):
    @dbus.service.method("org.freedesktop.DBus.ObjectManager", out_signature="a{oa{sa{sv}}}")
    def GetManagedObjects(self):
        return dbus.Dictionary({}, signature="oa{sa{sv}}")


DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()
name = dbus.service.BusName("org.bluez", bus)
Root(bus, "/")
GLib.MainLoop().run()
