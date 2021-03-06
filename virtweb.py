import libvirt
import json
import os
import base64
import tempfile
from PIL import Image
from keyboard import keycodes
from xml.dom import minidom

from flask import Flask, render_template

app = Flask(__name__)

conn = None

def get_conn():
    global conn
    try:
        conn.getInfo()
    except:
        print("Reopening")
        conn = libvirt.open(None)

def recvHandler(stream, buf, opaque):
    fd = opaque
    return os.write(fd, buf)

def get_isos():
    global conn
    get_conn()
    storage = conn.storagePoolLookupByName("default")
    isos = []
    for volume in storage.listVolumes():
        if volume[-4:] == '.iso':
            iso = storage.storageVolLookupByName(volume)
            isos.append(iso.path())
    return isos

def get_diskimages():
    global conn
    get_conn()
    storage = conn.storagePoolLookupByName("default")
    diskimages = []
    for volume in storage.listVolumes():
        if volume[-4:] == '.img':
            diskimage = storage.storageVolLookupByName(volume)
            diskimages.append(diskimage.path())
    return diskimages

def get_screenshot(domain,maxwidth=None,maxheight=None):
    get_conn()
    stream = conn.newStream(0)
    mime = domain.screenshot(stream,0,0)
    fd = os.tmpfile()
    tmp_raw = tempfile.NamedTemporaryFile()
    tmp_png = tempfile.NamedTemporaryFile(suffix=".jpg")
    fd = os.open(tmp_raw.name, os.O_WRONLY | os.O_TRUNC | os.O_CREAT, 0644)
    stream.recvAll(recvHandler,fd)
    im = Image.open(tmp_raw.name)
    if maxwidth != None or maxheight != None:
        if maxheight == None:
            wpercent = (maxwidth/float(im.size[0]))
            maxheight = int((float(im.size[1])*float(wpercent)))
        if maxwidth == None:
            hpercent = (maxheight/float(im.size[1]))
            maxwidth = int((float(im.size[0])*float(hpercent)))
        size = maxheight, maxwidth
        im.thumbnail(size, Image.ANTIALIAS)
    
    im.save(tmp_png.name)
    os.close(fd)
    data = base64.b64encode(open(tmp_png.name, 'r').read())
    tmp_raw.close()
    tmp_png.close()
    stream.finish()

    return {'mime': 'image/jpeg', 'data': data}

def get_domain(uuid):
    get_conn()
    domain = {}
    domain['object'] = conn.lookupByUUIDString(uuid)
    domain['name'] = domain['object'].name()
    domain['uuid'] = domain['object'].UUIDString()
    domain['status'] = "running"
    domain['id'] = domain['object'].ID()
    domain['dom'] = minidom.parseString(domain['object'].XMLDesc())
    domain['memory'] = int(domain['dom'].getElementsByTagName("memory")[0].firstChild.wholeText)/1000
    domain['current_memory'] = int(domain['dom'].getElementsByTagName("currentMemory")[0].firstChild.wholeText)/1000
    domain['vcpu'] = int(domain['dom'].getElementsByTagName("vcpu")[0].firstChild.wholeText)
    domain['disks'] = []
    domain['cdroms'] = []
    disks = domain['dom'].getElementsByTagName("disk")
    for disk_xml in disks:
        disk = {'disk': disk_xml, 'file': None}
        source = disk_xml.getElementsByTagName('source')
        if len(source) == 1:
            disk.update({'file': source[0].getAttribute('file')})
        if disk_xml.getAttribute('device') == 'disk':
            domain['disks'].append(disk);
        elif disk_xml.getAttribute('device') == 'cdrom':
            domain['cdroms'].append(disk);

    if domain['id'] != -1:
        domain['status'] = "running"
        domain['screenshot'] = get_screenshot(domain['object'])
    else:
        domain['status'] = "stopped"
        domain['screenshot'] = {'mime': 'image/png', 'data': base64.b64encode(open("static/stopped.png","r").read())}
    return domain

def get_domains():
    get_conn()
    running_domains = []
    for domain_id in conn.listDomainsID():
        domain = get_domain(conn.lookupByID(domain_id).UUIDString())
        running_domains.append(domain)
    for domain_name in conn.listDefinedDomains():
        domain = get_domain(conn.lookupByName(domain_name).UUIDString())
        running_domains.append(domain)
    return running_domains

@app.route("/domains.json")
def domains_json():
    dthandler = lambda obj: None #None if isinstance(obj, libvirt.virDomain) else None
    return json.dumps(get_domains(), default=dthandler)

@app.route("/")
def index():
    return render_template('index.tpl', **{'domains': get_domains()})

@app.route("/dom/<string:uuid>.json")
def single_domain_json(uuid):
    dthandler = lambda obj: None #None if isinstance(obj, libvirt.virDomain) else None
#    dthandler = lambda obj: None if isinstance(obj, libvirt.virDomain)  or isinstance(obj, libvirt) else None
    return json.dumps(get_domain(uuid), default=dthandler)

@app.route("/dom/<string:uuid>/mount_iso/<string:iso>")
def mount_iso(uuid, iso):
    global conn
    domain = get_domain(uuid)
    iso = base64.b64decode(iso)
    disk = domain['cdroms'][0]['disk']
    if domain['status'] != 'running':
        if domain['cdroms'][0]['file']:
            if iso == '---':
                disk.removeChild(disk.getElementsByTagName('source')[0])
            else:
                disk.getElementsByTagName('source')[0].setAttribute('file',iso);
        elif iso != '---':
            source = minidom.Document().createElement('source')
            source.setAttribute('file', iso)
            disk.appendChild(source)
        domain['object'].undefine()
        conn.defineXML(domain['dom'].toxml())
    else:
        if domain['cdroms'][0]['file']:
            if iso == '---':
                disk.removeChild(disk.getElementsByTagName('source')[0])
            else:
                disk.getElementsByTagName('source')[0].setAttribute('file',iso);
        elif iso != '---':
            source = minidom.Document().createElement('source')
            source.setAttribute('file', iso)
            disk.appendChild(source)
        domain['object'].attachDevice(disk.toxml())
    return domain['dom'].toxml()

@app.route("/dom/<string:uuid>/mount_diskimage/<string:diskimage>")
def mount_diskimage(uuid, diskimage):
    global conn
    domain = get_domain(uuid)
    diskimage = base64.b64decode(diskimage)
    disk = domain['disks'][0]['disk']
    if domain['status'] != 'running':
        if domain['disks'][0]['file']:
            if diskimage == '---':
                disk.removeChild(disk.getElementsByTagName('source')[0])
            else:
                disk.getElementsByTagName('source')[0].setAttribute('file',diskimage);
        elif diskimage != '---':
            source = minidom.Document().createElement('source')
            source.setAttribute('file', diskimage)
            disk.appendChild(source)
        domain['object'].undefine()
        conn.defineXML(domain['dom'].toxml())
    else:
        if domain['disks'][0]['file']:
            if diskimage == '---':
                disk.removeChild(disk.getElementsByTagName('source')[0])
            else:
                disk.getElementsByTagName('source')[0].setAttribute('file',diskimage);
        elif diskimage != '---':
            source = minidom.Document().createElement('source')
            source.setAttribute('file', diskimage)
            disk.appendChild(source)
        domain['object'].attachDevice(disk.toxml())
    return domain['dom'].toxml()

@app.route("/dom/<string:uuid>/delete")
def domain_delete(uuid):
    global conn
    domain = get_domain(uuid)
    if domain['status'] == 'running':
        domain['object'].destroy()
    domain['object'].undefine()
    return "OK";

@app.route("/dom/<string:uuid>/edit/<string:name>/<int:vcpus>/<int:memory>")
def domain_save(uuid, name, vcpus, memory):
    global conn
    domain = get_domain(uuid)
    if domain['status'] != "stopped":
        domain['object'].destroy()
    xmltext = domain['object'].XMLDesc()
    dom = minidom.parseString(xmltext)
    name_tag = dom.getElementsByTagName("name")[0]
    name_tag.firstChild.replaceWholeText(name)
    memory_tag = dom.getElementsByTagName("memory")[0]
    memory_tag.firstChild.replaceWholeText(memory*1000)
    current_memory_tag = dom.getElementsByTagName("currentMemory")[0]
    current_memory_tag.firstChild.replaceWholeText(memory*100)
    vcpu_tag = dom.getElementsByTagName("vcpu")[0]
    vcpu_tag.firstChild.replaceWholeText(vcpus)
    domain['object'].undefine()
    conn.defineXML(dom.toxml())
    return "OK"

@app.route("/dom/<string:uuid>")
def single_domain(uuid):
    return render_template('single_dom.tpl', **{'domain': get_domain(uuid), 'isos': get_isos(), 'diskimages': get_diskimages()})

@app.route("/sendkeys/<string:uuid>/<int:modifier>/<string:keys_string>")
def sendkeys(uuid, modifier, keys_string):
    keys_array = keys_string.split(",")
    keys = []
    for key in keys_array:
        try:
            key = int(key)
            key = keycodes[key]
            keys.append(key)
        except:
            pass
    domain = get_domain(uuid)
    domain['object'].sendKey(0, 0, keys, len(keys), 0)
    return "OK"

@app.route("/power/<string:uuid>/<string:power>")
def power(uuid, power):
    domain = get_domain(uuid)
    if power == 'on' and domain['status'] == 'stopped':
        domain['object'].create()
    if power == 'off' and domain['status'] != 'stopped':
        domain['object'].destroy()
    return "OK"

if __name__ == "__main__":
    app.debug = True
    app.run(host="127.0.0.1")
#    app.run(host="0.0.0.0")
