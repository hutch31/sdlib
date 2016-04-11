package DCUtil

import Chisel._

class DCInput[T <: Data](data: T) extends Module {
  val io = new Bundle {
    val c = new DecoupledIO(data).flip
    val p = new DecoupledIO(data)
  }
  val occ = Reg(init = Bool(false))
  val nxt_occ = io.c.valid & !io.p.ready | !io.p.ready & occ
  occ := nxt_occ
  val hold = Reg(io.c.bits)
  val load = io.c.valid & !io.p.ready & !occ | io.c.valid & io.p.ready & occ
  when (load) { hold := io.c.bits }
  io.p.bits := Mux(occ, hold, io.c.bits)
  io.p.valid := io.c.valid | occ
  io.c.ready := io.p.ready | !occ
}

class DCOutput[T <: Data](data: T) extends Module {
  val io = new Bundle {
    val c = new DecoupledIO(data).flip
    val p = new DecoupledIO(data)
  }
  val nxt_p_valid = io.c.valid | (!io.p.ready & io.p.valid)
  io.p.valid := Reg(next = nxt_p_valid, init=Bool(false))
  io.c.ready := io.p.ready | !io.p.valid
  val load = io.c.valid & io.c.ready
  //val nxt_p_data = Mux(load, io.c.bits, io.p.bits)
  io.p.bits := Reg(io.c.bits)
  when (load) {
    io.p.bits := io.c.bits
  }
}

class DCMirror[T <: Data](data: T, mirror: Int) extends Module {
  val io = new Bundle {
    val c = new DecoupledIO(data).flip
    val c_dst = UInt(INPUT, width = mirror)
    val p = Vec(mirror, new DecoupledIO(data))
  }
  // create a single holding register and tie all output data signals to it
  val hold = Reg(UInt(data))
  for (i <- 0 to mirror-1 by 1)
    io.p(i).bits := hold
  // create internal buses to represent collective ready and valid signals
  val p_drdy = UInt(width = mirror)
  for (i <- 0 to mirror-1 by 1)
    p_drdy(i) := io.p(i).ready
  val nxt_p_srdy = UInt(width = mirror)
  val p_srdy = Reg(next = nxt_p_srdy, init = UInt(0))
  val nxt_accept = (p_srdy === UInt(0)) | ((p_srdy != UInt(0)) & ((p_srdy & p_drdy) === p_srdy))
  io.c.ready := nxt_accept
  nxt_p_srdy := Mux(nxt_accept, Fill(mirror, io.c.valid) & io.c_dst, p_srdy & ~p_drdy)
  when (io.c.valid & nxt_accept) {
    hold := io.c.bits
  }
}

class WrapInput(w: Int) extends Module {
  val io = new Bundle {
    val c = new DecoupledIO(UInt(width=w)).flip
    val p = new DecoupledIO(UInt(width=w))
  }
  val dci = Module(new DCInput(io.c.bits))
  val dco = Module(new DCOutput(io.c.bits))
  io.c <> dci.io.c
  dci.io.p <> dco.io.c
  dco.io.p <> io.p
}

object mainObject {
  def main(args: Array[String]): Unit = {
    //val tutArgs = args.slice(1, args.length)
    val tutArgs = Array("--backend", "v")
    chiselMain(tutArgs, () => Module(new WrapInput(32)))
  }
}
