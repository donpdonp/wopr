resolvers += "Typesafe Repository" at "http://repo.typesafe.com/typesafe/releases/"

libraryDependencies  ++=  Seq(
    "com.typesafe.akka" % "akka-actor" % "2.0.3",
    "org.json4s" %% "json4s-native" % "3.0.0",
    "org.squeryl" %% "squeryl" % "0.9.5-2",
    "postgresql" % "postgresql" % "8.4-701.jdbc4"
  )

name := "WOPR"

version := "0.0.1"
