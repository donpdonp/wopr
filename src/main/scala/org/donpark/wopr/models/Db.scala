package org.donpark.wopr.models

import org.squeryl._

class Db extends Schema {
  val snapshots = table[Snapshot]

  override def drop = {
    Session.cleanupResources
    super.drop
  }
}

