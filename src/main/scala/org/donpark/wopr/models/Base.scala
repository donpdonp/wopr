package org.donpark.wopr.models

import java.sql.SQLException
import java.sql.Timestamp

import org.squeryl._
import dsl._
import dsl.ast.{RightHandSideOfIn, BinaryOperatorNodeLogicalBoolean}
import java.util.{Date, Calendar}
import org.squeryl.PrimitiveTypeMode._

class Base extends KeyedEntity[Int] {
  val id: Int = 0
  var created_at = new Timestamp(System.currentTimeMillis)
}

