# TODO: Do a proper job of escaping/transforming rather than just calling JSON.stringify
###
From: https://github.com/felixge/node-mysql#escaping-query-values

Numbers are left untouched

Booleans are converted to true / false

Date objects are converted to 'YYYY-mm-dd HH:ii:ss' strings

Buffers are converted to hex strings, e.g. X'0fa5'

Strings are safely escaped

Arrays are turned into list, e.g. ['a', 'b'] turns into 'a', 'b'

Nested arrays are turned into grouped lists (for bulk inserts), e.g. [['a', 'b'], ['c', 'd']] turns into ('a', 'b'), ('c', 'd')

Objects are turned into key = 'val' pairs for each enumerable property on the object. If the property's value is a function, it is skipped; if the property's value is an object, toString() is called on it and the returned value is used.

undefined / null are converted to NULL

NaN / Infinity are left as-is. MySQL does not support these, and trying to insert them as values will trigger MySQL errors until they implement support.

That said, I think I'd leave Dates with JSON.stringify since it results in an ISO-8601 string on node.js.
Same thing with 0x100 hex, which is returned as 256 from JSON.stringify
Converting undefined to null might be the most valuable in the list above.
I'd be inclined to convert NaN and Infinity to null, since DocumentDB only supports true JSON and these are not part of the spec.
Maybe some smarter conversion of arrays, nested arrays would be valuable. I already do this for IN and ARRAY_CONTAINS, but it might be
nice if that were generic.
Object seem to be handled properly by sql-from-mongo
###

sqlFromMongo = (mongoObject, collectionName) ->
  JOIN_LOOKUP = {$and: " AND ", $or: " OR ", $nor: " OR "}

  type = do ->  # from http://arcturo.github.com/library/coffeescript/07_the_bad_parts.html
    classToType = {}
    for name in "Boolean Number String Function Array Date RegExp Undefined Null".split(" ")
      classToType["[object " + name + "]"] = name.toLowerCase()

    (obj) ->
      strType = Object::toString.call(obj)
      classToType[strType] or "object"

  parseSingleKeyValuePair = (key, value, collectionName) ->
    if collectionName? and collectionName.length > 0
      prefix = collectionName + "."
    else
      prefix = ""
    switch key
      when "$not"
        s = sqlFromMongo(value, collectionName)
        if s.indexOf("(") is 0
          return "NOT " + s
        else
          return "NOT (" + s + ")"
      when "$and", "$or", "$nor"
        unless type(value) is "array"
          throw new Error("Use of $and, $or, or $nor operator requires an array as its parameter.")
        parts = []
        for o in value
          parts.push(sqlFromMongo(o, collectionName))
        joinOperator = JOIN_LOOKUP[key]
        s = "(" + parts.join(joinOperator) + ")"
        if key is "$nor"
          return "NOT " + s
        else
          return s
      else
        if type(value) is "object"
          parts = []
          s = "#{prefix + key} "
          for valueKey, valueValue of value
            switch valueKey
              when "$lt"
                parts.push(s + "< #{JSON.stringify(valueValue)}")
              when "$gt"
                parts.push(s + "> #{JSON.stringify(valueValue)}")
              when "$lte"
                parts.push(s + "<= #{JSON.stringify(valueValue)}")
              when "$gte"
                parts.push(s + ">= #{JSON.stringify(valueValue)}")
              when "$ne"
                parts.push(s + "<> #{JSON.stringify(valueValue)}")
              when "$eq"
                parts.push(s + "= #{JSON.stringify(valueValue)}")
              when "$in"
                if type(valueValue) is 'array'
                  if valueValue.length > 100
                    throw new Error("In DocumentDB the maximum number of values per IN expression is 100")
                  s = JSON.stringify(valueValue)
                  s = s.substr(1, s.length - 2)
                  return "#{prefix + key} IN (#{s})"
                else
                  return "ARRAY_CONTAINS(#{prefix + valueValue}, #{key})"
              when "$nin"
                if type(valueValue) is 'array'
                  if valueValue.length > 100
                    throw new Error("In DocumentDB the maximum number of values per IN expression is 100")
                  s = JSON.stringify(valueValue)
                  s = s.substr(1, s.length - 2)
                  return "NOT #{prefix + key} IN (#{s})"
                else
                  return "NOT ARRAY_CONTAINS(#{prefix + valueValue}, #{key})"
              when "$size"
                return "ARRAY_LENGTH(#{prefix + key}) = #{valueValue}"
              when "$exists"
                if valueValue
                  return "IS_DEFINED(#{prefix + key})"
                else
                  return "NOT IS_DEFINED(#{prefix + key})"
              when "$isArray"
                if valueValue
                  return "IS_ARRAY(#{prefix + key})"
                else
                  return "NOT IS_ARRAY(#{prefix + key})"
              when "$isBool"
                if valueValue
                  return "IS_BOOL(#{prefix + key})"
                else
                  return "NOT IS_BOOL(#{prefix + key})"
              when "$isNull"
                if valueValue
                  return "IS_NULL(#{prefix + key})"
                else
                  return "NOT IS_NULL(#{prefix + key})"
              when "$isNumber"
                if valueValue
                  return "IS_NUMBER(#{prefix + key})"
                else
                  return "NOT IS_NUMBER(#{prefix + key})"
              when "$isObject"
                if valueValue
                  return "IS_OBJECT(#{prefix + key})"
                else
                  return "NOT IS_OBJECT(#{prefix + key})"
              when "$isString"
                if valueValue
                  return "IS_STRING(#{prefix + key})"
                else
                  return "NOT IS_STRING(#{prefix + key})"
              when "$isPrimitive"
                if valueValue
                  return "IS_PRIMITIVE(#{prefix + key})"
                else
                  return "NOT IS_PRIMITIVE(#{prefix + key})"
              when "$startsWith"
                return "STARTSWITH(#{prefix + key}, #{JSON.stringify(valueValue)})"
              when "$endsWith"
                return "ENDSWITH(#{prefix + key}, #{JSON.stringify(valueValue)})"
              when "$contains"
                return "CONTAINS(#{prefix + key}, #{JSON.stringify(valueValue)})"
              when "$geoWithin"
                return "ST_WITHIN(#{prefix + key}, #{JSON.stringify(valueValue)})"
              when "$near"
                maxDistance = valueValue.$maxDistance
                minDistance = valueValue.$minDistance
                if maxDistance?
                  if minDistance?
                    return "(ST_DISTANCE(#{prefix + key}, #{JSON.stringify(valueValue.$geometry)}) <= #{maxDistance} AND ST_DISTANCE(#{prefix + key}, #{JSON.stringify(valueValue.$geometry)}) >= #{minDistance})"
                  else
                    return "ST_DISTANCE(#{prefix + key}, #{JSON.stringify(valueValue.$geometry)}) <= #{maxDistance}"
                if minDistance?
                  return "ST_DISTANCE(#{prefix + key}, #{JSON.stringify(valueValue.$geometry)}) >= #{minDistance}"
                else
                  throw new Error("No minDistance nor maxDistance found in {#{prefix + key}: #{JSON.stringify(value)}}")

              else
                throw new Error("sql-from-mongo does not recognize {#{prefix + key}: #{JSON.stringify(value)}}")
          keys = []
          for key2, value2 of value
            keys.push(key2)
          if keys.length is 1
            return parts[0]
          else
            return "(" + parts.join(" AND ") + ")"
        else
          return "#{prefix + key} = #{JSON.stringify(value)}"

  keys = []
  for key, value of mongoObject
    keys.push(key)
  if keys.length is 1
    return parseSingleKeyValuePair(keys[0], mongoObject[keys[0]], collectionName)
  else
    parts = []
    for key, value of mongoObject
      subObject = {}
      subObject[key] = value
      parts.push(sqlFromMongo(subObject, collectionName))
    return "(" + parts.join(" AND ") + ")"

exports.sqlFromMongo = sqlFromMongo