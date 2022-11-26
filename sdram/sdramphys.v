/**
 * Мини-эмулятор контроллера SDRAM на физическом чипе
 */

module sdramphys
(
    // Физический интерфейс DRAM
    input  wire         dram_clk,       // Тактовая частота памяти
    input  wire [ 1:0]  dram_ba,        // 4 банка
    input  wire [12:0]  dram_addr,      // Максимальный адрес 2^13=8192
    inout  wire [15:0]  dram_dq,        // Ввод-вывод
    input  wire         dram_cas,       // CAS
    input  wire         dram_ras,       // RAS
    input  wire         dram_we,        // WE
    input  wire         dram_ldqm,      // Маска для младшего байта
    input  wire         dram_udqm       // Маска для старшего байта
);

assign dram_dq  =  dram_we ? cached : 16'hZZZZ;

// 2MB
reg [15:0] memory[1024*1024];

initial $readmemh("sdram.hex", memory, 0);

// Команды к SDRAM
localparam
    cmd_loadmode    = 3'b000,
    cmd_refresh     = 3'b001,
    cmd_precharge   = 3'b010,
    cmd_activate    = 3'b011,
    cmd_write       = 3'b100,
    cmd_read        = 3'b101,
    cmd_burst_term  = 3'b110,
    cmd_nop         = 3'b111;

wire [ 2:0] command = {dram_ras, dram_cas, dram_we};
reg  [12:0] row;
reg  [15:0] cached;
reg  [12:0] mode;

always @(posedge dram_clk) begin

    case (command)

        cmd_loadmode: mode <= dram_addr;
        cmd_activate: row <= dram_addr;
        cmd_write: begin

            case ({dram_udqm, dram_ldqm})
            2'b00: memory[ {row, dram_addr[9:0]} ]       <= dram_dq;
            2'b01: memory[ {row, dram_addr[9:0]} ][15:8] <= dram_dq[15:8];
            2'b10: memory[ {row, dram_addr[9:0]} ][ 7:0] <= dram_dq[ 7:0];
            endcase

        end
        cmd_read: cached <= memory[ {row, dram_addr[9:0]} ];

    endcase

end

endmodule
