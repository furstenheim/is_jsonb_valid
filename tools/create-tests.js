const fs = require('fs-extra')
const path = require('path')
const testFolder = './../test/draft4/tests/draft4'
const ignoredTests = [
  'refRemote.json',
  'ref.json',
  'optional'
]
main()

async function main () {
  const files = await fs.readdir(testFolder)
  const addedFiles = []
  for (const file of files) {
    if (!ignoredTests.includes(file)) {
      const testFile = await fs.readJson(path.join(testFolder, file))
      const testLines = []
      const resultLines = []
      for (const testCase of testFile) {
        testLines.push(`-- ${testCase.description}`)
        resultLines.push(`-- ${testCase.description}`)
        for (const test of testCase.tests) {
          testLines.push(`-- ${test.description}`)
          resultLines.push(`-- ${test.description}`)
          testLines.push(`SELECT is_jsonb_valid('${JSON.stringify(testCase.schema)}', '${JSON.stringify(test.data)}');`)
          resultLines.push(`SELECT is_jsonb_valid('${JSON.stringify(testCase.schema)}', '${JSON.stringify(test.data)}');`)
          resultLines.push(' is_jsonb_valid ')
          resultLines.push('----------------')
          resultLines.push(testCase.valid ? ' t' : ' f')
          resultLines.push('(1 row)')
          resultLines.push('')
        }
      }
      const addedFile = file.match('[a-zA-Z]+')[0]
      addedFiles.push(addedFile)
      await fs.writeFile(path.join('../sql', addedFile + '.sql'), testLines.join('\n'))
      await fs.writeFile(path.join('../expected', addedFile + '.out'), resultLines.join('\n'))
    }
  }
  console.log(addedFiles.join(' '))
}