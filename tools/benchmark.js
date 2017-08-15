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
  console.time('is_jsonb_valid')
  const r = await client.query('SELECT * from (SELECT id, is_jsonb_valid($1, tweet) is_jsonb_valid from tweet_benchmark limit 10000) a where is_jsonb_valid = false', [tweetSchema])
  // const r = await client.query('SELECT id, is_jsonb_valid($1, tweet) from tweet_benchmark where id = 21853', [tweetSchema])
  console.timeEnd('is_jsonb_valid')
  console.log(r.rows)

  console.time('validate_json_schema')
  // You need to have postgres-json-schema installed
  const sqlR = await client.query('SELECT * from (SELECT id, validate_json_schema($1, tweet) is_jsonb_valid from tweet_benchmark limit 10000) a where is_jsonb_valid = false', [tweetSchema])
  // const r = await client.query('SELECT id, is_jsonb_valid($1, tweet) from tweet_benchmark where id = 21853', [tweetSchema])
  console.timeEnd('validate_json_schema')
  await client.end()
  console.log(sqlR.rows)
}
