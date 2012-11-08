package org.donpark.wopr

import akka.actor.Actor
import org.donpark.wopr.models._
import java.sql.Timestamp

class Dispatch extends Actor {
  def receive = {
    case ExchangeBalance => {
      val db = new Db
      db.snapshots.lookup(2)
      println("ExchangeBalance")
    }
    case _ => println("huh?")
  }
}