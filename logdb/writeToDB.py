#!/usr/bin/env python
#encoding: utf-8

import pymongo
import datetime
import os

client = pymongo.MongoClient(host="127.0.0.1", port=32017)
logdb = client['thlog']
col = logdb.account
col.drop()
col.create_index("createdAt", expireAfterSeconds=30*24*60*60 )

for fl in os.listdir("."):
	if os.path.isfile(fl) and os.path.splitext(fl)[1] == ".log":
		print("导入 "  + fl)
		tp = fl.split("_")
		if tp == None:
			continue
		file_handle = open(fl, "r")
		for line in file_handle.readlines():
			lt = line.split("# ")
			dt = eval( lt[1] )
			dt['createdAt'] = datetime.datetime.now()
			col = logdb[tp[0]]
			col.insert( dt )
	
