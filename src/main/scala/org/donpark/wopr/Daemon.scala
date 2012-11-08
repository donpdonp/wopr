package org.donpark.wopr

import org.json4s._
import org.json4s.native.JsonMethods._
import akka.actor.{Props, ActorSystem}
import org.squeryl.{SessionFactory, Session}
import org.squeryl.adapters.PostgreSqlAdapter

object Daemon {
  def main(args: Array[String]) {

    val configFile = io.Source.fromFile("config/settings.json").mkString
    val config = parse(configFile)

    db_setup(config)

    val system = ActorSystem("WOPR")
    val dispatch = system.actorOf(Props[Dispatch], name = "dispatch")
    dispatch ! "multi"
    dispatch ! ExchangeBalance
  }

  def db_setup(config: JValue) {
    println("db: " + (config \ "db"))
    Class.forName("org.postgresql.Driver")
    SessionFactory.concreteFactory = Some(()=>
     Session.create(
      java.sql.DriverManager.getConnection("..."),
       new PostgreSqlAdapter))
  }
}

