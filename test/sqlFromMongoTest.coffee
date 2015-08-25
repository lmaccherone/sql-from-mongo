{sqlFromMongo} = require('../')

exports.sqlFromMongoTest =

  testSimple: (test) ->
    mongoObject = {a: 1}
    expectedSQLString = "a = 1"
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = "col.a = 1"
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {a: "hello"}
    expectedSQLString = 'a = "hello"'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'col.a = "hello"'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testComplicated: (test) ->
    mongoObject = {a: 1, $and:[{b:2}, c: {$gt: 2, $lt: 10}, $nor:[{d: "a"}, {e: 20}, {$not: {f: 30}}]]}
    expectedSQLString = '(a = 1 AND (b = 2 AND ((c > 2 AND c < 10) AND NOT (d = "a" OR e = 20 OR NOT (f = 30)))))'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = '(col.a = 1 AND (col.b = 2 AND ((col.c > 2 AND col.c < 10) AND NOT (col.d = "a" OR col.e = 20 OR NOT (col.f = 30)))))'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testMultiple: (test) ->
    mongoObject = {a: 1, b: "hello"}
    expectedSQLString = '(a = 1 AND b = "hello")'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = '(col.a = 1 AND col.b = "hello")'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {a: 1, b: "hello", c: 3}
    expectedSQLString = '(a = 1 AND b = "hello" AND c = 3)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = '(col.a = 1 AND col.b = "hello" AND col.c = 3)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testInequality: (test) ->
    mongoObject = {price: {$lt: 9.95}}
    expectedSQLString = "price < 9.95"
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = "col.price < 9.95"
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {price: {$lt: 9.95, $gt: 0.77}}
    expectedSQLString = "(price < 9.95 AND price > 0.77)"
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = "(col.price < 9.95 AND col.price > 0.77)"
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testAnd: (test) ->
    mongoObject = {$and: [{a: 1}, {b: {$gt: 2}}]}
    expectedSQLString = "(a = 1 AND b > 2)"
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = "(col.a = 1 AND col.b > 2)"
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)
    test.done()

  testOr: (test) ->
    mongoObject = {$or: [{a: 1}, {b: {$gt: 2}}]}
    expectedSQLString = "(a = 1 OR b > 2)"
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = "(col.a = 1 OR col.b > 2)"
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)
    test.done()

  testNor: (test) ->
    mongoObject = {$nor: [{a: 1}, {b: {$gt: 2}}]}
    expectedSQLString = "NOT (a = 1 OR b > 2)"
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = "NOT (col.a = 1 OR col.b > 2)"
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)
    test.done()

  testNot: (test) ->
    mongoObject = {$not: {a: 1, b: {$gt: 2}}}
    expectedSQLString = "NOT (a = 1 AND b > 2)"
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = "NOT (col.a = 1 AND col.b > 2)"
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {$not: {a: 1}}
    expectedSQLString = "NOT (a = 1)"
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = "NOT (col.a = 1)"
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testIn: (test) ->
    mongoObject = {a: {$in: [1, 2, "hello"]}}
    expectedSQLString = 'a IN (1,2,"hello")'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'col.a IN (1,2,"hello")'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {'"a"': {$in: "x"}}
    expectedSQLString = 'ARRAY_CONTAINS(x, "a")'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'ARRAY_CONTAINS(col.x, "a")'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {"1": {$in: "x"}}
    expectedSQLString = 'ARRAY_CONTAINS(x, 1)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'ARRAY_CONTAINS(col.x, 1)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testNin: (test) ->
    mongoObject = {a: {$nin: [1, 2, "hello"]}}
    expectedSQLString = 'NOT a IN (1,2,"hello")'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'NOT col.a IN (1,2,"hello")'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {'"a"': {$nin: "x"}}
    expectedSQLString = 'NOT ARRAY_CONTAINS(x, "a")'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'NOT ARRAY_CONTAINS(col.x, "a")'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {"1": {$nin: "x"}}
    expectedSQLString = 'NOT ARRAY_CONTAINS(x, 1)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'NOT ARRAY_CONTAINS(col.x, 1)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testSize: (test) ->
    mongoObject = {a: {$size: 10}}
    expectedSQLString = 'ARRAY_LENGTH(a) = 10'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'ARRAY_LENGTH(col.a) = 10'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)
    test.done()

  testExists: (test) ->
    mongoObject = {a: {$exists: true}}
    expectedSQLString = 'IS_DEFINED(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'IS_DEFINED(col.a)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {a: {$exists: false}}
    expectedSQLString = 'NOT IS_DEFINED(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'NOT IS_DEFINED(col.a)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testIsArray: (test) ->
    mongoObject = {a: {$isArray: true}}
    expectedSQLString = 'IS_ARRAY(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)

    mongoObject = {a: {$isArray: false}}
    expectedSQLString = 'NOT IS_ARRAY(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)

    test.done()

  testIsBool: (test) ->
    mongoObject = {a: {$isBool: true}}
    expectedSQLString = 'IS_BOOL(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'IS_BOOL(col.a)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {a: {$isBool: false}}
    expectedSQLString = 'NOT IS_BOOL(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'NOT IS_BOOL(col.a)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testIsNull: (test) ->
    mongoObject = {a: {$isNull: true}}
    expectedSQLString = 'IS_NULL(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'IS_NULL(col.a)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {a: {$isNull: false}}
    expectedSQLString = 'NOT IS_NULL(col.a)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testIsNumber: (test) ->
    mongoObject = {a: {$isNumber: true}}
    expectedSQLString = 'IS_NUMBER(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'IS_NUMBER(col.a)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {a: {$isNumber: false}}
    expectedSQLString = 'NOT IS_NUMBER(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'NOT IS_NUMBER(col.a)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testIsObject: (test) ->
    mongoObject = {a: {$isObject: true}}
    expectedSQLString = 'IS_OBJECT(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'IS_OBJECT(col.a)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    mongoObject = {a: {$isObject: false}}
    expectedSQLString = 'NOT IS_OBJECT(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    expectedSQLString = 'NOT IS_OBJECT(col.a)'
    test.equal(sqlFromMongo(mongoObject, "col"), expectedSQLString)

    test.done()

  testIsString: (test) ->
    mongoObject = {a: {$isString: true}}
    expectedSQLString = 'IS_STRING(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)

    mongoObject = {a: {$isString: false}}
    expectedSQLString = 'NOT IS_STRING(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)

    test.done()

  testIsPrimitive: (test) ->
    mongoObject = {a: {$isPrimitive: true}}
    expectedSQLString = 'IS_PRIMITIVE(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)

    mongoObject = {a: {$isPrimitive: false}}
    expectedSQLString = 'NOT IS_PRIMITIVE(a)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)

    test.done()

  testStartsWith: (test) ->
    mongoObject = {a: {$startsWith: "something"}}
    expectedSQLString = 'STARTSWITH(a, "something")'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    test.done()

  testEndsWith: (test) ->
    mongoObject = {a: {$endsWith: "something"}}
    expectedSQLString = 'ENDSWITH(a, "something")'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    test.done()

  testContains: (test) ->
    mongoObject = {a: {$contains: "something"}}
    expectedSQLString = 'CONTAINS(a, "something")'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    test.done()

  testGeoWithin: (test) ->
    mongoObject = {locationField: {$geoWithin: {type: "Polygon", coordinates: [[31.9, -4.8], [10.2, -5.6], [44.8, 23.9]]}}}
    expectedSQLString = 'ST_WITHIN(locationField, {"type":"Polygon","coordinates":[[31.9,-4.8],[10.2,-5.6],[44.8,23.9]]})'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    test.done()

  testGeoNear: (test) ->
    mongoObject = {pointExpression: {$near: {$geometry: {type: "Point", coordinates: [10.2, -6.7]}, $maxDistance: 20}}}
    expectedSQLString = 'ST_DISTANCE(pointExpression, {"type":"Point","coordinates":[10.2,-6.7]}) <= 20'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)

    mongoObject = {pointExpression: {$near: {$geometry: {type: "Point", coordinates: [10.2, -6.7]}, $minDistance: 20}}}
    expectedSQLString = 'ST_DISTANCE(pointExpression, {"type":"Point","coordinates":[10.2,-6.7]}) >= 20'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)

    mongoObject = {pointExpression: {$near: {$geometry: {type: "Point", coordinates: [10.2, -6.7]}, $minDistance: 20, $maxDistance: 40}}}
    expectedSQLString = '(ST_DISTANCE(pointExpression, {"type":"Point","coordinates":[10.2,-6.7]}) <= 40 AND ST_DISTANCE(pointExpression, {"type":"Point","coordinates":[10.2,-6.7]}) >= 20)'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)

    test.done()

  testLongKey: (test) ->
    mongoObject = {'CONCAT(food.id, " ", food.name)': "1234 Rice"}
    expectedSQLString = 'CONCAT(food.id, " ", food.name) = "1234 Rice"'
    test.equal(sqlFromMongo(mongoObject), expectedSQLString)
    test.done()