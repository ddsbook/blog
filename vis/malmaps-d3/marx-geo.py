import csv
import geoip2.database

def to_string(ip):
  return ".".join(map(lambda n: str(ip>>n & 0xFF), [24,16,8,0]))

reader = geoip2.database.Reader('~/.maxmind/GeoLite2-City.mmdb')

with open('marx.csv', 'rb') as marx:
  with open('marx-geo.csv', 'w') as f:
    flyreader = csv.reader(marx, delimiter=',', quotechar='"')
    for fly in flyreader:
      longIP = fly[2]
      strIP = to_string(int(fly[2]))
      try:
        r = reader.city(strIP)
        f.write("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" % 
                                    (fly[0], fly[1], longIP, fly[3], fly[4], fly[5], fly[6],
                                     strIP,
                                     r.country.iso_code,
                                     r.country.name, 
                                     r.subdivisions.most_specific.name,
                                     r.subdivisions.most_specific.iso_code,
                                     r.postal.code,
                                     r.location.latitude,
                                     r.location.longitude))
      except:
        f.write("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" % 
                                     (fly[0], fly[1], longIP, fly[3], fly[4], fly[5], fly[6],
                                      strIP, "", "", "", "", "", "", ""))

