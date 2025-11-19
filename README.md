# README

This README would normally document whatever steps are necessary to get the
application up and running.
==========================================================================

* Prerequisites:
- Ruby version: 3.4.7
- Install Bundler
- Rails version: 8.1.1
* The breakdown for assignment:
- Define the routes for API
- Implement actions corresponding the defined routes
- Requires the params
- Split short link services for encoding and decoding
- Applying https://tinyurl.com/ where the short_code, long_url are stored
- Tinyurl supported the API for encoding and decoding
- Test API for happy cases and error cases on local
- Set up deployment
- Test again on server
- Write the Readme for scaling and security system

===========================================================================

* Security:
User can submit malicious params for encode and can share to someone, to
avoid that Cross Site Scripting and Open Redirect Vulnerabilities, parameters
should be validated, using also filtering and escaping. If not, it can occur:
- That could be executed malicious script, users would lose our session and
attacker can take over them, or malware infection
- Redirect to another website, there are some risks on that page

===========================================================================

* Scalability:
May be high traffic from decode reads, cause slow execution and response to
client. We can implement an in-memory cache such as Redis before calling
for receiving third-party information, where short_code and long_url will be
mapped.

* Collision:
When using third-party, there are some problem about listening about it, that
could be time-out response or getting error from it. We should set the retry
loop with max of retry time for a request, and rescue for the last time of
the loops

===========================================================================

Things you may want to cover:

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
