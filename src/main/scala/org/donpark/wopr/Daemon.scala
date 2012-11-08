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
    dispatch ! ExchangeBalance
  }

  def db_setup(config: JValue) {
    Class.forName("org.postgresql.Driver")
    val JString(driver_url) = (config \ "db" \ "url")
    val JString(username) = (config \ "db" \ "username")
    val JString(password) = (config \ "db" \ "password")

    SessionFactory.concreteFactory = Some(()=>
     Session.create(
      java.sql.DriverManager.getConnection(driver_url, username, password),
       new PostgreSqlAdapter))
  }
}

