[![build status](https://secure.travis-ci.org/lmaccherone/sql-from-mongo.svg)](http://travis-ci.org/lmaccherone/sql-from-mongo)
# sql-from-mongo #

Copyright (c) 2015, Lawrence S. Maccherone, Jr.

_Simple conversion from MongoDB-like syntax to SQL WHERE clauses_

This implements all but a few of MongoDB's query operators and adds a few that were easy to implement. My target SQL is DocumentDB but I suspect that this will work as-is with most SQL implementations. Neither MongoDB nor DocumentDB support cross-document joins so that greatly simplifies things.

## Installation

    npm install -save sql-from-mongo

## Usage

the sqlFromMongo function takes three parameters:

1. A JavaScript object with your MongoDB-like query
2. (optional) A string containing the collection/table name to use as a prefix for any 
   field/column names. Note, you can omit this and fully qualify your variables yourself.
3. (optional) A list of fields as an array of strings. Note, if you provide this, then it will respond with a full
   query (i.e. "SELECT __ FROM __ WHERE"), not just a WHERE clause.

Examples:
   
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
    
You could include the above output in the where clause of a full SQL query like this:

    query = "SELECT * FROM c WHERE #{sqlFromMongo({State: {$startsWith: "In "}}, 'c')}"
    
which sets query to:

    SELECT * FROM c WHERE STARTSWITH(c.State, "In ")
    
More conveniently, though, you can provide a list of fields or '*' as the third parameter and it will build the entire
SELECT statement for you. For example:

    o = {a: 1}
    console.log(sqlFromMongo(o, "c", "*"))
    # SELECT * from c WHERE c.a = 1
    
    o = {a: 1}
    console.log(sqlFromMongo(o, "c", ["a", "b"]))
    # SELECT c.a, c.b from c WHERE c.a = 1
    
There is currently no support for things like `SELECT 1...`. If you need that then omit the fields parameter and build
the full query using sqlFromMongo only for the WHERE clause.
    
## Supported operators (from [here](http://docs.mongodb.org/manual/reference/operator/query/))

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

### MongoDB operators not supported:
  * $type I didn't want to duplicate the MongoDB behavior including the BSON codes. Use
    $isBool, $isNumber, etc.
  * $all Easy with UDF so maybe later
  * $regex Easy with UDF so maybe later. In the mean time, maybe $startsWith, $endsWith, or 
    $contains will serve.
  * $elemMatch Never used this in MongoDB so not on my must have list. Implementation similar
    to $all but think $any
  * $mod Could probably do this without UDF but never used it so not high on my list although
    it could be useful for sampling
    
### DocumentDB operators (from [here](https://azure.microsoft.com/en-us/documentation/articles/documentdb-sql-query/#where-clause) and [here](https://azure.microsoft.com/en-us/documentation/articles/documentdb-sql-query/#built-in-functions)) not supported:
  * Bitwise operators
  * Modulus
  * String concatenate operator but do sorta support CONCAT built in function (see below)
  * BETWEEN but wouldn't be hard to support. Just ask. In the mean time, use the inequality 
    operators (which are also index optimized to the best of my knowledge)
  * Ternary (?) and Coalesce (??) operators
  * Quoted property accessor food["tags"] instead of food.tags. Should be easy to implement if 
    you need it for SQL keyword/field conflict or field names that contain punctuation. Just
    ask.
  * Sorta... If you need to use any of the built in functions like the unary math operators 
    (ABS, FLOOR, etc.), string functions (CONCAT, LTRIM, etc.), array functions not listed
    above (ARRAY_SLICE and ARRAY_CONCAT), or the geo functions not listed above (ST_ISVALID
    and ST_ISVALIDDETAILED), then you can omit the second parameter when you call sqlFromMongo 
    and fully qualify your field/column names yourself. Example: 
    
        console.log(sqlFromMongo({'CONCAT(food.id, " ", food.name)': "1234 Rice"}))
        # CONCAT(food.id, " ", food.name) = "1234 Rice"
        
## Immune to SQL Injection

Since all scalars are escaped with JSON.strinigify(), the SQL produced by sql-from-mongo is immune from SQL Injection
attacks. It's hard to prove a negative, but it has been tested with all data types (string, number, array, true/false,
undefined, NaN, Infinity, Date, Buffer, Uint8Array and we don't see any way for an injection to get through. 
Worst case, it can produce invalid SQL for DocumentDB with certain data types (undefined, for example).
        
## Version history
 
 * 0.2.1 - 2016-05-27 - Just returns the input if it's already SQL
 * 0.2.0 - 2015-11-19 - Added ability to generate full SQL (including SELECT and FROM clauses)
 * 0.1.3 - 2015-10-09 - Properly escape (via JSON.strinigify()) string values for inequalities
 * 0.1.2 - 2015-09-20 - Made it all one function so it can be mixed in to a documentdb-utils sproc
 * 0.1.1 - 2015-08-25 - Updated Docs. Fixed bug that was not allowing strings as scalars.
 * 0.1.0 - 2015-08-24 - Initial version