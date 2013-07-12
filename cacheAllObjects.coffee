# cacheAllObjects
fs = require 'fs'

http = require 'http'
http.globalAgent.maxSockets = 30

console.log "trying to connect"
fs.writeFileSync "triples.n3", ""

metRunner = require './metRunner'

objectCallback = (objectJson) ->
	console.log "in objectCallback"
	console.log objectJson
	
	# objectnumber

	objectid = objectJson['id']

	filepath = "objects/#{objectid}.json"
	fs.writeFile filepath, JSON.stringify(objectJson, null, " ")

  # triplify
  id = "http://data.metmuseum.org/objects#"+objectid
  trips = []
  
  whatProp = "http://data.metmuseum.org/rels#what"
  for key, value in objectJson['What']?
    what = "http://data.metmuseum.org/whats#" + encodeURIComponent(value)
    trips.push(triplify(id, whatProp, what))

  whoProp = "http://data.metmuseum.org/rels#who";
  for key, value in objectJson['Who']?
    what = "http://data.metmuseum.org/who#" + encodeURIComponent(value)
    trips.push(triplify(id, whoProp, what));

  whereProp = "http://data.metmuseum.org/rels#where"
  for key, value in objectJson['Where']?
    what = "http://data.metmuseum.org/location#" + encodeURIComponent(value)
    trips.push(triplify(id, whereProp, what))

  relatedProp = "http://data.metmuseum.org/rels#related"
  for key, value in objectJson['related-artworks']?
    what = "http://data.metmuseum.org/object#" + encodeURIComponent(value)
    trips.push(triplify(id, relatedProp, what))

  imageProp = "http://data.metmuseum.org/rels#images"
  for key, value in objectJson['images']?
    what = "http://data.metmuseum.org/image#" + encodeURIComponent(value)
    trips.push(triplify(id, imageProp, what))

  console.log(trips)

  accProp = "http://data.metmuseum.org/rels#AccessionNumber"
  if objectJson['Accession Number']?
    what = "http://data.metmuseum.org/accession#" + encodeURIComponent(objectJson['Accession Number'])
    trips.push(triplifyString(id, accProp, what))


triplify = (sub, pred, obj) ->
  string = "<"+ sub + "> <" +  pred + "> <" + obj + "> . \n"
  console.log "**************************************"
  console.log string

  fs.appendFileSync "triples.n3", string
  string

filterCallback = (objectJson) ->
	console.log "in filterCallback"
	console.log objectJson)
	true

finishedCallback = ->
	console.log "in finishedCallback"

metRunner = metRunner.getMetRunner({
									numObjects : 10,	
									startpage : 2000,
									endpage : 6500,
									objectCallback: objectCallback, 
									filterCallback : filterCallback,
									finishedCallback : finishedCallback});

metRunner.run()