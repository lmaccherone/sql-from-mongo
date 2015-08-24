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
              parts.push(s + "< #{valueValue}")
            when "$gt"
              parts.push(s + "> #{valueValue}")
            when "$lte"
              parts.push(s + "<= #{valueValue}")
            when "$gte"
              parts.push(s + ">= #{valueValue}")
            when "$ne"
              parts.push(s + "<> #{valueValue}")
            when "$eq"
              parts.push(s + "= #{valueValue}")
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
        return "#{prefix + key} = #{value}"

sqlFromMongo = (mongoObject, collectionName) ->
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