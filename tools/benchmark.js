process.chdir(__dirname)
require('dotenv').config({path: './tweets.env'})
const pg = require('pg')
const fs = require('fs-extra')
main()
async function main () {
  const tweetSchema = fs.readJSONSync('./tweet-schema.json')
  const client = new pg.Client()
  await client.connect()
  client.on('notice', function (m) {
    console.log(m.toString())
  })
  // TO make sure we have latest version
  await client.query('DROP EXTENSION IF EXISTS is_jsonb_valid')
  await client.query('CREATE EXTENSION is_jsonb_valid')
  const r = await client.query('SELECT id, is_jsonb_valid($1, tweet) from tweet_benchmark limit 2', [tweetSchema])
  console.log(r.rows)
  await client.end()
}
