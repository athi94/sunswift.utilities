#! /usr/bin/python
import os
import sys
from os.path import join
APPEND=' | UNSW Solar Racing Team - www.sunswift.com'

def find_tty_usb(idVendor, idProduct, idProdString):
    #print (idVendor)
    """find_tty_usb('067b', '2302') -> '/dev/ttyUSB0'"""
    # Note: if searching for a lot of pairs, it would be much faster to search
    # for the enitre lot aBust once instead of going over all the usb devices
    # each time.
    for dnbase in os.listdir('/sys/bus/usb/devices'):
        dn = join('/sys/bus/usb/devices', dnbase)
        if not os.path.exists(join(dn, 'idVendor')):
            continue
        
        #Look for given USB Vendor ID    
        idv = open(join(dn, 'idVendor')).read().strip()
        if idv != idVendor:
            continue
        
        #look for given USB Product ID
        idp = open(join(dn, 'idProduct')).read().strip()
        if idp != idProduct:
            continue
        
        #look for given USB product string with the Sunswift tag appended
        idps = open(join(dn, 'product')).read().strip()
        #print dn
        #print idps
        #print open(join(dn, 'manufacturer')).read().strip()
        #print open(join(dn, 'serial')).read().strip()

        if idps != idProdString:
            continue
        for subdir in os.listdir(dn):
            if subdir.startswith(dnbase+':'):
                for subsubdir in os.listdir(join(dn, subdir)):
                    if subsubdir.startswith('ttyUSB'):
                        print('/dev/'+subsubdir)
                        return join('/dev', subsubdir)


if __name__ == "__main__":
  #print sys.argv[1]
  find_tty_usb('0403', '6001', sys.argv[1])
