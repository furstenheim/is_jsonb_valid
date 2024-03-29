const fs = require('fs-extra')
const path = require('path')
const testFolder = './../test/draft4/tests/draft4'
const testFolderV7 = './../test/draft4/tests/draft7'
const ignoredTests = [
  'refRemote.json',
  'optional',
  'definitions.json', // it uses remotes schemas
  'format.json', // not implemented
  'unknownKeyword.json' // this seems to be about unknown remotes

]
main()

async function main () {
  await parseFolder(testFolder, 'v4')
  await parseFolder(testFolderV7, 'v7')
}

async function parseFolder (folder, version) {
  const files = await fs.readdir(folder)
  const functionNames = {
    'v4': 'is_jsonb_valid',
    'v7': 'is_jsonb_valid_draft_v7',
  }
  const functionName = functionNames[version]
  if (!functionName) {
    throw new Error(`Unknown version: '${version}'`)
  }
  const individualIgnoredTests = {
    'enum.json': [
      'nul characters in strings' // postgres does not support null characters in unicode
    ],
    'const.json': [
      'nul characters in strings'
    ],
    'id.json': [
      'match $ref to id', // remote ref
      'no match on enum or $ref to id' // remote ref
    ],
    // $ref are either impossible to implement (remote reference) or very complicated to implement (recursive ref, relative ids...). We limit the scope of the library to just refs at root level.
    'ref.json': [
      'remote',
      'Recursive references',
      'escaped pointer ref',
      'Location-independent', // Only support refs anchored at root
      'id must be resolved against nearest parent, not just immediate parent', // Only support refs anchored at root
      '$ref resolves to /definitions/base_foo, data validates', // $ref by id not supported
      '$ref prevents a sibling id from changing the base uri', // $ref by id not supported
      '$ref resolves to /definitions/base_foo, data validates', // $ref by id not supported
      'refs with quote', // we do not support url encoding in the ref,
      '$ref resolves to /definitions/base_foo, data does not validate', // remote ref
      'URN base URI with URN and JSON pointer ref', // ref not anchored at root
      'refs with relative uris and defs', // library only supports refs at root, not in parent schema
      'relative refs with absolute uris and defs', // library only supports refs at root, not in parent schema
      'simple URN base URI with $ref via the URN', // this uses $id
      'URN base URI with URN and anchor ref', // URN ids are not supported
      'ref to if', // this requires a remote schema
      'ref to then', // this requires a remote schema
      'ref to else', // this requires a remote schema
      'ref with absolute-path-reference', // this requires a remote schema
    ]
  }



  const addedFiles = []
  for (const file of files) {
    if (!ignoredTests.includes(file)) {
      const testFile = await fs.readJson(path.join(folder, file))
      const testLines = []
      const resultLines = []
      for (const testCase of testFile) {
        if (individualIgnoredTests[file] && individualIgnoredTests[file].find(d => testCase.description.indexOf(d) !== -1)) {
          continue
        }

        testLines.push(`-- ${testCase.description}`)
        resultLines.push(`-- ${testCase.description}`)
        for (const test of testCase.tests) {
          if (individualIgnoredTests[file] && individualIgnoredTests[file].find(d => test.description.indexOf(d) !== -1)) {
            continue
          }
          testLines.push(`-- ${test.description}`)
          resultLines.push(`-- ${test.description}`)
          testLines.push(`SELECT ${functionName}('${escapeJSON(testCase.schema)}', '${escapeJSON(test.data)}');`)
          resultLines.push(`SELECT ${functionName}('${escapeJSON(testCase.schema)}', '${escapeJSON(test.data)}');`)
          resultLines.push(` ${functionName} `)
          resultLines.push('-'.repeat(functionName.length + 2))
          resultLines.push(test.valid ? ' t' : ' f')
          resultLines.push('(1 row)')
          resultLines.push('')
        }
      }
      resultLines.push('')
      const addedFile = `${file.match('[a-zA-Z]+')[0]}${version === 'v4' ? '' : '.' + version}`
      addedFiles.push(addedFile)
      await fs.writeFile(path.join('../sql', addedFile + '.sql'), testLines.join('\n'))
      await fs.writeFile(path.join('../expected', addedFile + '.out'), resultLines.join('\n'))
    }
  }
  console.log(addedFiles.join(' '))
}

function escapeJSON(input) {
  return JSON.stringify(input).replaceAll(`'`, `''`)
}