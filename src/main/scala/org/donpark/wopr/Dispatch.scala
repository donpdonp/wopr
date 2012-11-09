package org.donpark.wopr

import akka.actor.Actor
import org.donpark.wopr.models._
import java.sql.Timestamp
import org.squeryl.PrimitiveTypeMode._

class Dispatch extends Actor {
  def receive = {
    case ExchangeBalance => {
      println("ExchangeBalance")
      transaction {
        println("Looking up snapshot")
        val shot = Daemon.db.snapshots.lookup(2)
        println(shot.get.created_at)
      }

    }
    case _ => println("huh?")
  }
}