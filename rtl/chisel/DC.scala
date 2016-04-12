package DCUtil

import Chisel._

/** @param data The data type for the payload
  */
class DCInput[D <: Bits](data: D)  extends Module {
  val io = new Bundle {
    val c = new DecoupledIO(data).flip
    val p = new DecoupledIO(data)
  }
  val nxt_occupied = Bool()
  val occupied = Reg(next = nxt_occupied, init = Bool(false))
  val nxt_hold = UInt()
  val hold = Reg(next = nxt_hold)
  val drain = occupied & io.p.ready
  val load = io.c.valid & io.c.ready & (!io.p.ready | drain)
  val nxt_c_drdy = (!occupied & !load) | (drain & !load)
  val c_drdy = Reg(next = nxt_c_drdy, init = Bool(false))

  when (occupied)
    { io.p.bits := hold }
  .otherwise
    { io.p.bits := io.c.bits }
  io.p.valid := (io.c.valid & io.c.ready) | occupied
  nxt_hold := hold
  when (load) {
    nxt_hold := io.c.bits
    nxt_occupied := Bool(true)
  }.elsewhen (drain) {
    nxt_occupied := Bool(false)
  }.otherwise {
    nxt_occupied := occupied
  }
  io.c.ready := c_drdy
}

/** @param data The data type for the payload
  */
class DCOutput[T <: Data](data: T) extends Module {
  val io = new Bundle {
    val c = new DecoupledIO(data).flip
    val p = new DecoupledIO(data)
  }
  val nxt_p_valid = io.c.valid | (!io.p.ready & io.p.valid)
  io.p.valid := Reg(next = nxt_p_valid, init=Bool(false))
  io.c.ready := io.p.ready | !io.p.valid
  val load = io.c.valid & io.c.ready
  //val nxt_p_data = UInt(io.c.bits)
  val p_bits = Reg(io.c.bits)
  when (load) {
    p_bits := io.c.bits
  }
  io.p.bits := p_bits
}

/** @param data The data type for the payload
  * @param mirror The number of consumers
  */
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
  p_drdy := UInt(0)
  for (i <- 0 to mirror-1 by 1)
    p_drdy(i) := io.p(i).ready
  val nxt_p_srdy = UInt(width = mirror)
  val p_srdy = Reg(next = nxt_p_srdy, init = UInt(0))
  for (i <- 0 to mirror-1 by 1)
    io.p(i).valid := p_srdy(i)
  val nxt_accept = (p_srdy === UInt(0)) | ((p_srdy != UInt(0)) & ((p_srdy & p_drdy) === p_srdy))
  io.c.ready := nxt_accept
  nxt_p_srdy := Mux(nxt_accept, Fill(mirror, io.c.valid) & io.c_dst, p_srdy & ~p_drdy)
  when (io.c.valid & nxt_accept) {
    hold := io.c.bits
  }
}

/*
class WrapInput(w: Int) extends Module {
  val io = new Bundle {
    val c = new DecoupledIO(UInt(width=w)).flip
    val p = new DecoupledIO(UInt(width=w))
  }
  val dci = Module(new DCInput(io.c.bits))
  //val dco = Module(new DCOutput(io.c.bits))
  io.c <> dci.io.c
  dci.io.p <> io.p
  //dci.io.p <> dco.io.c
  //dco.io.p <> io.p
}

object mainObject {
  def main(args: Array[String]): Unit = {
    //val tutArgs = args.slice(1, args.length)
    val tutArgs = Array("--backend", "v")
    chiselMain(tutArgs, () => Module(new WrapInput(32)))
  }
}
*/
