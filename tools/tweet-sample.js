process.chdir(__dirname)
require('dotenv').config({path: './tweets.env'})
const Twit = require('twit')
const Channel = require('async-csp').Channel
const pg = require('pg')
const twitter = new Twit({
  consumer_key: process.env.TWITTER_API_KEY,
  consumer_secret: process.env.TWITTER_API_SECRET,
  access_token: process.env.TWITTER_ACCESS_TOKEN,
  access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
})

main()

async function main () {
// tweets -> (CSP) -> pg
  const tweetPgCSP = new Channel(100)
  await setUpDb()
  readTweets(tweetPgCSP)
  // consumers reading from the channel
  for (let i = 0; i < 50; i++) {
    saveTweet(tweetPgCSP)
  }
}

function readTweets (channel) {
  const tweetStream = twitter.stream('statuses/sample')

  tweetStream.on('tweet', function (tweet) {
    channel.put(tweet)
  })
  tweetStream.on('error', e => console.error(e))
}

async function saveTweet (channel) {
  const client = new pg.Client()
  await client.connect()
  while (true) {
    const tweet = await channel.take()
    await client.query(`
    insert into tweet_benchmark (tweet) values ($1)`, [tweet])
  }
}

async function setUpDb () {
  const client = new pg.Client()
  await client.connect()
  const res = await client.query(`
    CREATE TABLE IF NOT EXISTS tweet_benchmark (id bigserial, tweet jsonb);
  `)
  console.log(res)
  await client.end()
}
