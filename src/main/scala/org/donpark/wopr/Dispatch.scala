package org.donpark.wopr

import akka.actor.Actor
import org.donpark.wopr.models._
import java.sql.Timestamp
import org.squeryl.PrimitiveTypeMode._
import scalaj.http.{Http, HttpOptions}
import org.json4s._
import org.json4s.native.JsonMethods._

class Dispatch extends Actor {
  def receive = {
    case ExchangeBalance => {
      println("ExchangeBalance")
      transaction {
        println("Looking up snapshot")
        val shot = Daemon.db.snapshots.lookup(2)
        println(shot.get.created_at)
      }
      val ticker = Http("https://mtgox.com/api/0/data/ticker.php").
                      options(HttpOptions.connTimeout(5000)).asString
      val tj = parse(ticker)
      println(tj)
    }
    case _ => println("huh?")
  }
}