package org.donpark.wopr

import akka.actor.Actor
import org.donpark.wopr.models._
import java.sql.Timestamp
import org.squeryl.PrimitiveTypeMode._
import scalaj.http.{Http, HttpOptions}

class Dispatch extends Actor {
  def receive = {
    case ExchangeBalance => {
      println("ExchangeBalance")
      transaction {
        println("Looking up snapshot")
        val shot = Daemon.db.snapshots.lookup(2)
        println(shot.get.created_at)
      }
      println(Http("http://news.ycombinator.com").
        options(HttpOptions.connTimeout(5000)).asString)

    }
    case _ => println("huh?")
  }
}