package org.donpark.wopr

import org.json4s._
import org.json4s.native.JsonMethods._
import akka.actor.ActorSystem

object Daemon {
  def main(args: Array[String]) {

    val configFile = io.Source.fromFile("config/settings.json").mkString
    val config = parse(configFile)

    val system = ActorSystem("WOPR")
  }
}

