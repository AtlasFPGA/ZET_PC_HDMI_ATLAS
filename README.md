# ZET_PC_HDMI_ATLAS

ZET de Zeus Gómez Marmolejo GPL V3.

https://ch.linkedin.com/in/zeusgm

EL core es un core adelantado a su época dado que se creó hace más de 10 años con una estructura de wishbone lo que lo hace un core de pc totamente modular,
y tenía una web asociada a Él, buscando por zet zeus alucina,
se pueden encontrar aún las copias que quedaron tanto del foro como de la páquina web principal del mismo.


El repositorio principal es:

https://github.com/marmolejo

El core se ha adaptado de los siguientes fuentes:

https://github.com/mvvproject/ReVerSE-U16/tree/master/u16_zet

Fuentes usan la licencia GPL3

![Posición relativa de las roms dentro del JIC del ZET](https://github.com/AtlasFPGA/ZET_PC_HDMI_ATLAS/blob/main/flash/JIC.JPG)

Aquí se puede ver el vídeo en una placa Terasic DE1:



[![Zet en acción](https://img.youtube.com/vi/xLmnIhynMUg/0.jpg)](https://www.youtube.com/watch?v=xLmnIhynMUg)


Falla la instancias de memoria en quartus se ha usado un quartus 20.1 lite, pero si es cierto que con el mismo codigo en un quartus bastante más antiguo no se ha dado caso de fallo en las instancias de memoria asincronas, pero a partir del 20.1 que es principalemnte el que uso a dado errores de sintesis en la generación de memorias indicando que son asincronas.


Mostramos los fallos en tres tipos de bloques verilog donde se instancian memorias en el ZET-PC:

Info (276007): RAM logic "zet:zet|zet_core:core|zet_micro_data:micro_data|zet_micro_rom:micro_rom|rom" is uninferred due to asynchronous read logic


``` 
//
`include "defines.v"

// altera message_off 10030
//  get rid of the warning about
//  not initializing the ROM

module zet_micro_rom (
    input [`MICRO_ADDR_WIDTH-1:0] addr,
    output [`MICRO_DATA_WIDTH-1:0] q
  );

  // Registers, nets and parameters
  reg [`MICRO_DATA_WIDTH-1:0] rom[0:2**`MICRO_ADDR_WIDTH-1];

  // Assignments
  assign q = rom[addr];

  // Behaviour
  initial $readmemb("micro_rom.dat", rom);
endmodule
//
``` 
        
este sería  uno de los ejemplos y no se usa una señal de reloj...

Info (276007): RAM logic "bootrom:bootrom|rom" is uninferred due to asynchronous read logic
``` 
//
module bootrom (
    input clk,
    input rst,

    // Wishbone slave interface
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    input  [19:1] wb_adr_i,
    input         wb_we_i,
    input         wb_tga_i,
    input         wb_stb_i,
    input         wb_cyc_i,
    input  [ 1:0] wb_sel_i,
    output        wb_ack_o
  );

  // Net declarations
  reg  [15:0] rom[0:127];  // Instantiate the ROM

  wire [ 6:0] rom_addr;
  wire        stb;

  // Combinatorial logic
  assign rom_addr = wb_adr_i[7:1];
  assign stb      = wb_stb_i & wb_cyc_i;
  assign wb_ack_o = stb;
  assign wb_dat_o = rom[rom_addr];

  initial $readmemh("bootrom.dat", rom);

endmodule
//
``` 
en esta si se tiene clk pero no se usa en el módulo en verilog

Info (276007): RAM logic "fmlbrg:fmlbrg|fmlbrg_datamem:datamem|ram0" is uninferred due to asynchronous read logic

``` 
//
module fmlbrg_datamem #(
  parameter depth = 8
) (
  input sys_clk,

  /* Primary port (read-write) */
  input [depth-1:0] a,
  input [1:0] we,
  input [15:0] di,
  output [15:0] dout,

  /* Secondary port (read-only) */
  input [depth-1:0] a2,
  output [15:0] do2
);

reg [7:0] ram0[0:(1 << depth)-1];
reg [7:0] ram1[0:(1 << depth)-1];

wire [7:0] ram0di;
wire [7:0] ram1di;

wire [7:0] ram0do;
wire [7:0] ram1do;

wire [7:0] ram0do2;
wire [7:0] ram1do2;

reg [depth-1:0] a_r;
reg [depth-1:0] a2_r;

always @(posedge sys_clk) begin
  a_r <= a;
  a2_r <= a2;
end

/*
 * Workaround for a strange Xst 11.4 bug with Spartan-6
 * We must specify the RAMs in this order, otherwise,
 * ram1 "disappears" from the netlist. The typical
 * first symptom is a Bitgen DRC failure because of
 * dangling I/O pins going to the SDRAM.
 * Problem reported to Xilinx.
 */
 
always @(posedge sys_clk) begin
  if(we[1])
    ram1[a] <= ram1di;
end
assign ram1do = ram1[a_r];
assign ram1do2 = ram1[a2_r];

always @(posedge sys_clk) begin
  if(we[0])
    ram0[a] <= ram0di;
end
assign ram0do = ram0[a_r];
assign ram0do2 = ram0[a2_r];

assign ram0di = di[7:0];
assign ram1di = di[15:8];

assign dout = {ram1do, ram0do};
assign do2 = {ram1do2, ram0do2};

endmodule
//
``` 
y en esta ultima si se pasa el reloj y lo usa pero aún así lo considera asíncrona.
