package org.donpark.wopr.models

import org.squeryl.Schema
import org.squeryl.annotations.Column
import java.sql.Timestamp

class Snapshot(var name: String) extends Base with java.io.Serializable {
  def this() = this("bob")
}
