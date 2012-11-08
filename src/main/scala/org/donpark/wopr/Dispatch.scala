package org.donpark.wopr

import akka.actor.Actor

class Dispatch extends Actor {
  def receive = {
   case _ => println("huh?")
  }
}