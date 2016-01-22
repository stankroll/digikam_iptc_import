#!/usr/bin/python

import os
import pyexiv2
import sqlite3 as sql

# Does a tag exist:
#   select tags.id, tags.pid, tags.name
#     from tags
#    where name = 'Tom'
#      and pid = 24 -- 0=root (ie. no parent)
#   ; 
#
def create_tags(iptc_category):
    "Split the iptc category passed and return the id of the lowest level tag."
    tag_cursor = con.cursor()
    print '   ', iptc_category
    taglist = iptc_category.split('.')
    parent_tag_id = 0
    for tag in taglist:
        print '       ', tag
        tag_cursor.execute("select tags.id " +
                           "  from tags "     +
                           " where name = :Name " +
                           "   and pid  = :Pid", {"Name": tag, "Pid": parent_tag_id})
        tag_id = tag_cursor.fetchone()
        if tag_id == None:
            print "            digikam tag not found for:", tag
        else:
            print "            digikam tag_id =", tag_id[0]
    return

con = sql.connect('/home/srkzm3/Pictures/digikam4.db')
with con:
    cur = con.cursor()
    cur.execute("select images.id, albumroots.specificpath || albums.relativepath || '/' || images.name " + 
                "  from images join albums on images.album = albums.id " + 
                "              join albumroots on albums.albumroot = albumroots.id")
#                "              join albumroots on albums.albumroot = albumroots.id LIMIT 20")
    while True:
      digikam_image = cur.fetchone()
      if digikam_image == None:
        break
      print 'file =', digikam_image[1]
      imagedata = pyexiv2.ImageMetadata(digikam_image[1])
      try:
        imagedata.read()
        tag = imagedata.get('Iptc.Application2.SuppCategory')
        if tag == None:
          print '    No IPTC imagedata found for', digikam_image[1]
        else:
          for category in tag.value:
            create_tags(category)
      except IOError:
        pass
