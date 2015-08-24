# sql-from-mongo #

Copyright (c) 2015, Lawrence S. Maccherone, Jr.

_Simple conversion from MongoDB-like syntax to SQL WHERE clauses_

## Installation

    npm install -save sql-from-mongo

## Usage
    
    {sqlFromMongo} = require('sql-from-mongo')
    
    o = {a: 1}
    console.log(sqlFromMongo(o, "food"))
    # food.a = 1
    
    o = {a: {$in: [1, 2, "hello"]}}
    console.log(sqlFromMongo(o, "food"))
    # food.a IN (1,2,"hello")

    o = {a: 1, $and: [{b: 2}, c: {$gt: 2, $lt: 10}, $nor:[{d: 10}, {e: 20}, {$not: {f: 30}}]]}
    console.log(sqlFromMongo(o, "z"))
    # (z.a = 1 AND (z.b = 2 AND ((z.c > 2 AND z.c < 10) AND NOT (z.d = 10 OR z.e = 20 OR NOT (z.f = 30)))))
    
## Supported operators

### Logical & Conjunctive:

  * $or OR
  * $and AND
  * $not NOT
  * $nor NOT(... OR ...)

### Comparison:

  * $gt >
  * $gte >=
  * $lt <
  * $lte <=
  * $ne <>
  * $eq =

### Other:

  * $in Note, this will work in the traditional way like `{a: {$in: [1, 2, "hello"]}}` but it
    will also work in situations like `{'"a"': {$in: "x"}}` where x is the field name. Also,
    note that if you expect the field to contain an array, you must use this form because the
    traditional MongoDB thing of matching a scalar to array fields is not supported by SQL.
    Note, this latter form does not use an index so combine with other highly selective
    criteria and/or do the comparison on the calling side.
  * $nin
  * $size test array length
  * $exists `{field: {$exists: <boolean>}}`. If boolean is false, then NOT $exists

### Geo:

  * $geoWithin
  * $near 
  
        pointField: $near {
            $geometry: {
                type: "Point" ,
                coordinates: [ <longitude> , <latitude> ]
            },
            $maxDistance: <distance in meters>
        }

    Translates to: `ST_DISTANCE(pointField, {'type': 'Point', 'coordinates':[31.9, -4.8]}) <= $maxDistance`.
    Appropriate translation generated with $minDistance or if both are provided.

### Additional (not in MongoDB but easy with DocumentDB):

#### Types: (all of these behave like $exists allowing you to specify false for the boolean)

  * $isArray `{field:{$isArray: <boolean>}}`
  * $isBool
  * $isNull Note, this is not the same as $exists: false
  * $isNumber
  * $isObject
  * $isString
  * $isPrimative
  
#### Strings: 

  * $startsWith
  * $endsWith
  * $contains

### Not supported:
  * $type I didn't want to duplicate the MongoDB behavior including the BSON codes. Use
    $isBool, $isNumber, etc.
  * $all Easy with UDF so maybe later
  * $regex Easy with UDF so maybe later
  * $elemMatch Never used this in MongoDB so not on my must have list. Implementation similar
    to $all but think $any
  * $mod Could probably do this without UDF but never used it so not high on my list although
    it could be useful for sampling