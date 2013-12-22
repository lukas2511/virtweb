# virtweb

This is a simple webinterface for libvirt.

It is not really well designed, just hacked together.
I wanted to build an alternative to virt-manager to install some machines.

Current Features:

 - [List Machines (With live preview-image and name)](screenshots/list.png)
 - [Basic control over machines (keyboard-only, without VNC or JAVA or anything, just pure screenshot/base64/json/ajax magic.)](screenshots/control.png)
 - ["Auto-Type" of text (put it in a box, press send, it will do checks if it can send those characters and do so, useful for urls and stuff)](screenshots/autotype.png)
 - Turn machines on or off
 - [Change name, max. memory and number of vcpus of machines](screenshots/edit.png)
 - [Mount/Unmount ISO-Images](screenshots/mountiso.png)

Planned Features:

 - Show host statistics (Used memory, Free disk space, ...)
 - Basic Statistics (If possible, depends on the libvirt Python-API)
 - Create new virtual machines (install from ISO or preseed file/textbox, maybe with templates)
 - Manage storage (Create/Remove/Attach/Dettach Disks)

Known Bugs:

 - There is no authentication. There probably never will be. This was intended to be used over an SSH tunnel on a machine with no other users.
 - Keyboard input is incomplete (keymapping issues...), slow (i don't really know why... it shouldn't be.) and kinda buggy (double key-presses, only on "manual" control, libvirt-api has no way to send single keyup or -down events just -presses, would need some client-side "debouncing")
