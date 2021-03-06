# Move your place

<a href="http;//www.premesti.se">Premesti.Se</a> is a site for communications
between parents when they want to switch places in kindergartens.

## Getting Started

You can download and run the project locally to see how it works.
In source you can see usage of the:

* Rails 5
* Neo4j database
* yarn installed: bootstrap 3, jquery 3, font awesome 4, snapsvg, select2
* svg animations

Graph database is chosen since we need to match moves in format A->B, B->A
(I want to move from A to B, so please find me who wants to move from B to A).
But there is also trio variant; A->B, B->C and C->A.

## Neo4j Database

It runs on Java 8 so download Java SDK from Oracle.
To install Neo4j use this rails tasks

~~~
rails neo4j:install[community-latest,development]
rails neo4j:install[community-latest,test]

## this will change db/neo4j/development/conf/neo4j.conf
rails neo4j:config[development,$(expr $NEO4J_PORT + 2)]
rails neo4j:config[test,$(expr $NEO4J_TEST_PORT + 2)]
~~~

Start neo4j server with:

~~~
rails neo4j:start[development]
gnome-open http://localhost:$(expr $NEO4J_PORT + 2) # http://localhost:7042/browser/
rails neo4j:start[test]
gnome-open http://localhost:$(expr $NEO4J_TEST_PORT + 2) # http://localhost:7047/
~~~

Note that when you are changing the ports, then run `spring stop` to reload new
env.

Drop migrate and seed with custom rake tasks.

~~~
rake db:drop
rake db:migrate
rake db:seed
~~~

## Run

Before running localy you need to get npm packages with:

~~~
yarn install
~~~

Than run as usual

~~~
rails s
~~~

and open browser at <http://localhost:3000>

## Locale

Serbian cyrillic is default. When you add new items in one language, you can
automatically translate to other (from cyrillic to latin and en) with rake tasks

~~~
rails translate:missing
rails translate:copy
~~~

## Test

Run test with

~~~
bin/rails test
bin/rails test:system
guard
~~~

If guard or test runner does not see `<class:Application>': Please set env
variables for NEO4J server ://:@: (RuntimeError)` than `spring stop` can help.

## Deployment

It is currently deployed to Heroku using free services.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of
conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Authors

This project is designed and created at TRK INNOVATION llc by:

* by [duleorlovic](https://github.com/duleorlovic)
