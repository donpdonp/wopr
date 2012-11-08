package org.donpark.wopr

import org.json4s._
import org.json4s.native.JsonMethods._

object Daemon {
  def main(args: Array[String]) {

    val configFile = io.Source.fromFile("config.json").mkString
    val config = parse(configFile)
  }
}

