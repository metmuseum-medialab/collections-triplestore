### 

Code to call all objects in scrapi, and run the callback function

```
metRunner = require "metRunner"
 
metRunner = metRunner.getMetRunner
  objectCallback: objectCallback 
  filterCallback: filterCallback
  finishedCallback: finishedCallback

metRunner.run()
```

  `objectCallback`: function to run for each individual object page callback
  - input : json array of object data from scrapi call

  `filtercallback`: function, returns true or false, to process or skip the object
  - input : json array of object data from scrapi call
 
  `finishedCallback` : method to run when done.
###

# if we're running server-side, this stuff needs to happen.

getMetRunner = (options) -> new metRunner(options)

$ = require "jquery"
fs = require "fs"
crypto = require "crypto"

if typeof module isnt "undefined"
  module.exports.getMetRunner = getMetRunner
  $ = require "jquery"
  jQuery = $
else
  console.log "some sort of problem creating module"

metRunner = (options) ->
  @keepGettingPages = true
  @numObjects = options.numObjects
  @startpage = options.startpage
  @endpage = options.endpage
  @pendingCalls = 0
  @fromCache = 0
  @notFromCache = 0
  @totalUrlsCalled = 0
  @totalWrittenToCache = 0
  @baseUrl = "http://scrapi.org/"
  @objectCallback = options.objectCallback
  @filterCallback = options.filterCallback
  @finishedCallback = options.finishedCallback

metRunner::run = ->
  @runOnAllMetObjects()

metRunner::runOnAllMetObjects = ->
  #	iterate over all objects called from /ids,
  page = @startpage
  @getMetObjectsPage page

metRunner::getMetObjectsPage = (pageNumber) ->
  url = @baseUrl + "ids/" + pageNumber
  realthis = this
  
  #	console.log("calling objectlist url " + url);
  @cacheProxy url, (idList) ->
    realthis.processMetList idList

  realthis = this
  pageNumber++
  if @keepGettingPages and pageNumber < @endpage
    setTimeout (->
      realthis.getMetObjectsPage pageNumber
    ), 1000

metRunner::wait = ->
  realthis = this
  if @pendingCalls > 3000
    console.log @pendingCalls + " too many pending, waiting"
    setTimeout (->
      realthis.wait()
    ), 1000

metRunner::processMetList = (idsList) ->
  
  #	this.wait();
  console.log "idslist "
  console.log idsList.ids
  if idsList.ids.length is 0
    console.log "no objects on this page"
    @keepGettingPages = false
    return
  realthis = this
  $(idsList.ids).each (key, value) ->
    objectUrl = realthis.baseUrl + "object/" + value
    
    #		console.log("calling object url " + objectUrl);
    realthis.cacheProxy objectUrl, (objectJson) ->
      realthis.processMetObject objectJson


metRunner::processMetObject = (objectJson) ->
  
  # call the callback
  return  if @filterCallback(objectJson) is false
  @objectCallback objectJson

metRunner::getFromCache = (url) ->
  
  # couch or filesystem?
  path = @urlToCacheHash(url)
  if fs.existsSync(path)
    @fromCache++
    
    # get data file and return;
    data = fs.readFileSync(path,
      encoding: "utf-8"
    )
    console.log "got data from cache"
    console.log data
    return false  if data.trim() is ""
    data = JSON.parse(data)
    console.log data
    return data
  
  #	console.log("no data at " + path);
  @notFromCache++
  false

metRunner::storeToCache = (url, data) ->
  
  # couch or filesystem
  dir = @urlToDirPath(url)
  
  #		console.log("dir " + dir + " not found");
  fs.mkdirSync dir, 0777, true  unless fs.existsSync(dir)
  filepath = @urlToCacheHash(url)
  fs.writeFile filepath, JSON.stringify(data, null)
  @totalWrittenToCache++

metRunner::urlToCacheHash = (url) ->
  hash = crypto.createHash("md5").update(url).digest("hex")
  path = @urlToDirPath(url) + "/" + hash + ".json"
  path

metRunner::urlToDirPath = (url) ->
  hash = crypto.createHash("md5").update(url).digest("hex")
  
  #	console.log("hash of " + url + " is " + hash);
  d1 = hash.substring(0, 2)
  d2 = hash.substring(2, 4)
  d3 = hash.substring(4, 6)
  path = "cache/" + d1 + "/" + d2 + "/" + d3
  path

metRunner::cacheProxy = (url, callback) ->
  # if use the url as key, try to get the object from cache.
  # if not in cache, load from url, then save in cache. 
  
  # call callback when data retreived.
  console.log "in cacheproxy, pending calls is " + @pendingCalls
  realthis = this
  
  # check in cache
  data = @getFromCache(url)
  @totalUrlsCalled++
  console.log "from cache: " + @fromCache + "  not: " + @notFromCache + " total : " + @totalUrlsCalled
  if data
    callback data
    realthis.finishedCallback()  if realthis.pendingCalls is 0
    return
  
  @pendingCalls++
  console.log "not in cache, getting data from url " + url
  $.ajax
    url: url
    error: (retdata) ->
      realthis.pendingCalls--
      console.log "failure"
      console.log retdata

    success: (retdata) ->
      realthis.pendingCalls--
      if retdata is ""
        console.log "no results"
        return true
      
      realthis.storeToCache url, retdata
      callback retdata
      realthis.finishedCallback()  if realthis.pendingCalls is 0