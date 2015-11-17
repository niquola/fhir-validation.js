profiles = require('../fhir/profiles-resources.json')
profiles.entry = profiles.entry.concat(require('../fhir/profiles-types.json').entry)


exports.validate = (validator, metadata_fn)->

SD = {}

for e in profiles.entry when e.resource.resourceType == 'StructureDefinition'
  SD[e.resource.name] = e.resource


isObject = (v)->
  !!v && not Array.isArray(v) && v.constructor == Object

upcase = (x)-> x[0].toUpperCase() + x.slice(1)

clone = (x)-> JSON.parse(JSON.stringify(x))

assoc = (obj, key, val)->
  nobj = clone(obj)
  nobj[key] = val
  nobj

select_keys = (obj, keys)->
  res = {}
  for k in keys when obj[k]
    res[k] = obj[k]
  res

put_in = (obj, path, val)->
  cur = obj
  while path.length > 1 
    k = path.shift()
    cur._elements = cur._elements || {}
    cur._elements[k]  = cur._elements[k]  || {}
    cur = cur._elements[k]
  cur[path.shift()] = val
  obj

extract_reference = (refs)->
  refs.map (x)->
    if not x.profile
      console.log(JSON.stringify(x))
    else
      x.profile[0].split("/")[-1..][0]

node_attrs = (m)->
  if m.type && m.type[0] && m.type[0].code == 'Reference'
    type: 'Reference'
    resources: extract_reference(m.type)
    min: m.min
    max: m.max
  else
    if m.nameReference
      type: 'nameReference'
      reference: m.nameReference
      min: m.min
      max: m.max
    else if m.path == 'Resource'
      type: 'Resource'
      min: m.min
      max: m.max
    else if not m.type
      if m.path.indexOf('.value') > -1
        primitive: true
        base: m.base
      else if m.path == 'Element'
        # nop
      else
        throw new Error("Unexpeceted #{JSON.stringify(m)}")
    else if m.type.length > 1
      throw new Error("Unexpeceted #{JSON.stringify(m.type)}")
    else
      type: m.type[0].code
      min: m.min
      max: m.max

add_to_index = (idx, sd)->
  snap = sd.snapshot.element
  for e in snap
    if e.path.indexOf('[x]') > -1
      parts = e.path.split('.')
      last = parts[(parts.length - 1)]
      ppath = parts[0..-2]
      for tp in e.type
        parts[(parts.length - 1)] = last.replace('[x]', upcase(tp.code))
        put_in(idx, parts, node_attrs(assoc(e, 'type', [tp])))
    else
      put_in(idx, e.path.split('.'), node_attrs(e))
  idx

keys = (m)-> k for k,v of m

idx = {}
for k,sd of SD
  idx = add_to_index(idx, sd)

console.log(keys(idx))

console.log(JSON.stringify(idx._elements.Patient))
