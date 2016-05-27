sqlFromMongo = (mongoQueryObject, collectionName, fields) ->
  if fields? and not collectionName?
    throw new Error("Must provide a collectionName if fields is provided.")

  JOIN_LOOKUP = {$and: " AND ", $or: " OR ", $nor: " OR "}

  type = do ->  # from http://arcturo.github.com/library/coffeescript/07_the_bad_parts.html
    classToType = {}
    for name in "Boolean Number String Function Array Date RegExp Undefined Null".split(" ")
      classToType["[object " + name + "]"] = name.toLowerCase()

    (obj) ->
      strType = Object::toString.call(obj)
      classToType[strType] or "object"

  if type(mongoQueryObject) is 'string' and mongoQueryObject.toUpperCase().indexOf('SELECT') is 0 # It's already SQL
    return mongoQueryObject

  parseSingleKeyValuePair = (key, value, collectionName) ->
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

  if collectionName? and collectionName.length > 0
    prefix = collectionName + "."
  else
    prefix = ""

  keys = []
  for key, value of mongoQueryObject
    keys.push(key)
  if keys.length is 1
    parts = [parseSingleKeyValuePair(keys[0], mongoQueryObject[keys[0]], collectionName)]
  else
    parts = []
    for key, value of mongoQueryObject
      subObject = {}
      subObject[key] = value
      parts.push(sqlFromMongo(subObject, collectionName))

  if parts.length is 1
    sql = parts[0]
  else
    sql = "(" + parts.join(" AND ") + ")"
  if fields?
    if fields is '*' or (fields[0] is '*') or fields is true
      fieldsString = '*'
    else
      fieldStringParts = (prefix + field for field in fields)
      fieldsString = fieldStringParts.join(", ")
    sql = "SELECT #{fieldsString} FROM #{collectionName} WHERE " + sql
  return sql

exports.sqlFromMongo = sqlFromMongo