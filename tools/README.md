## Tools

Run `npm i` to install dependencies. 

### Create test
From the cl do `npm run create-test`, it will adapt the json tests from 
[JSON-Schema-Test-Suite](https://github.com/json-schema-org/JSON-Schema-Test-Suite) to sql tests that are run on make.

### Sample tweets
From the cl do `npm run tweet-sample`. It will create a table in you db called tweet_benchmark and start inserting tweets
from the streaming API.

To be able to run this script you will need to add a file "tweets.env" with the credentials for
postgres and one twitter app. You can find an example of such file in './tweets.env.sample', make sure not to commit your
credentials.

According to Twitter usage conditions one is not allowed to permanently store tweets. So make sure to remove the table after you are done.

### Benchmark
This assumes that you already have a table tweet_benchmark with tweets. (See previous section). Run `npm run benchmark`

