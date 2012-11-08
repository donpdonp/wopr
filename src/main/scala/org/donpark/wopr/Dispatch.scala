package org.donpark.wopr

import akka.actor.Actor

class Dispatch extends Actor {
  def receive = {
   case ExchangeBalance => println("ExchangeBalance")
   case _ => println("huh?")
  }
}