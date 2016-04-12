package DCUtil

import Chisel._

class WrapInput extends Module {
  val io = new Bundle {
    val c = Vec(4, new DecoupledIO(UInt(width=8)).flip)
    val p = Vec(4, new DecoupledIO(UInt(width=8)))
  }
  val rrarb = Module(new RRArbiter(io.c(0).bits, 4))
  val mirr  = Module(new DCMirror(io.c(0).bits, 4))
  val select = UInt(1) << rrarb.io.chosen
  mirr.io.c_dst := select
  io.c <> rrarb.io.in
  rrarb.io.out <> mirr.io.c
  mirr.io.p <> io.p
}

object mainObject {
  def main(args: Array[String]): Unit = {
    //val tutArgs = args.slice(1, args.length)
    val tutArgs = Array("--backend", "v")
    chiselMain(tutArgs, () => Module(new WrapInput()))
  }
}
