// CKE = 1 ВСЕГДА
// CS  = 0 АКТИВИРОВАН

module sdram
(
    input               clock,              // 100 Mhz
    input               reset_n,            // =0 Сброс
    input               noinit,             // =0 Инициализировать память

    // Интерфейс взаимодействия
    input       [25:0]  address,            // Запрошенный адрес байта
    input       [ 7:0]  in,                 // Данные на запись в память
    input               we,
    output reg  [ 7:0]  out,
    output              ready,

    // Физический интерфейс
    output              dram_clk,
    output reg  [ 1:0]  dram_ba,
    output reg  [12:0]  dram_addr,
    inout       [15:0]  dram_dq,
    output              dram_cas,
    output              dram_ras,
    output              dram_we,
    output reg          dram_ldqm,
    output reg          dram_udqm
);

assign dram_clk = clock;

// WE=0 -> Запись в память; 1=Чтение из памяти
assign dram_dq  = dram_we ? 16'hZZZZ : {in, in};

// Условие разблокировки процессора
wire   invd   = (ff_address != address) || (ff_data != in && we) || ff_first;
assign ready  = ff_ready && !invd;

// Команда на выход
assign {dram_ras, dram_cas, dram_we} = command;

initial begin dram_ldqm = 1'b1; dram_udqm = 1'b1; end

// Команды к SDRAM
// ------------------------------------------------------------------------
localparam

    //                   RCW
    cmd_loadmode    = 3'b000, // Загрузка регистра режима
    cmd_refresh     = 3'b001, // Обновления
    cmd_precharge   = 3'b010, // Перезарядка
    cmd_activate    = 3'b011, // Активация строки
    cmd_write       = 3'b100, // Запись
    cmd_read        = 3'b101, // Чтение
    cmd_burst_term  = 3'b110, // Остановка
    cmd_nop         = 3'b111; // NOP
// --------------------------------------

localparam

    ST_INIT         = 0,
    ST_IDLE         = 1,
    ST_PRECHARGE    = 2,
    ST_PROCESS      = 3;

reg [ 2:0]  command      = 3'b111;
reg [ 3:0]  st           = 1'b0;
reg [ 3:0]  fn           = 1'b0;
reg [17:0]  timer        = 1'b0;
reg [12:0]  bank_charge  = 1'b0;
reg [25:0]  ff_address   = 1'b0;     // Текущий адрес
reg [ 7:0]  ff_data      = 1'b0;
reg         ff_we        = 1'b0;
reg         ff_first     = 1'b0;
reg         ff_ready     = 1'b0;
reg         precharge    = 1'b0;

always @(posedge clock)
// Сброс модуля
if (reset_n == 1'b0) begin

    st          <= noinit ? ST_IDLE : ST_INIT;
    command     <= cmd_nop;
    ff_we       <= 1'b0;
    ff_ready    <= 1'b0;
    ff_first    <= 1'b1;
    dram_ldqm   <= 1'b1;
    dram_udqm   <= 1'b1;
    precharge   <= 1'b0;

end
// Операционный режим
else case (st)

    // Инициализация
    ST_INIT: begin

        timer <= timer + 1'b1;

        case (timer)
        18'd200000: begin command <= cmd_precharge; dram_addr <= 11'b1_00_000_0_0_000; end
        18'd200012: begin command <= cmd_refresh;   end          //  A    CAS2    FULL
        18'd200068: begin command <= cmd_loadmode;  dram_addr <= 11'b1_00_001_0_0_111; end
        18'd200080: begin      st <= ST_IDLE; end
        default:    begin command <= cmd_nop; end
        endcase

    end

    // Состояние ожидания
    ST_IDLE: begin

        fn          <= 1'b0;
        command     <= cmd_activate;
        precharge   <= ~precharge;

        // Перезарядка очередного банка происходит через команду
        if (precharge) begin

            st          <= ST_PRECHARGE;
            dram_ba     <= 2'b00;
            dram_addr   <= bank_charge[12:0];
            bank_charge <= bank_charge + 1'b1;

        end
        // Выполнение операции с памятью
        else begin

            // 1. Если поменялся адрес, то прочитать (записать) новый
            // 2. Поменялись данные при записи
            if (invd)
            begin

                st          <= ST_PROCESS;
                ff_ready    <= 1'b0;
                ff_first    <= 1'b0;
                ff_address  <= address;
                ff_data     <= in;
                ff_we       <= we;

                dram_ba     <= address[25:24];  // 2 BIT
                dram_addr   <= address[23:11];  // 13 BIT
                bank_charge <= bank_charge + 1;

                dram_ldqm   <=  address[0] & we;
                dram_udqm   <= !address[0] & we;

            end

        end

    end

    // Перезарядка строки
    ST_PRECHARGE: case (fn)

        0,1: begin command <= cmd_nop;       fn <= fn + 1'b1; end
        2:   begin command <= cmd_precharge; fn <= 3; dram_addr[10] <= 1'b1;  end
        3:   begin command <= cmd_nop;       st <= ST_IDLE; end

    endcase

    // Чтение или запись
    ST_PROCESS: case (fn)

        // Ожидание активации строки
        0,1,4,5: begin command <= cmd_nop; fn <= fn + 1'b1; end

        // Запись или чтение
        2: begin

            fn        <= 3;
            command   <= ff_we ? cmd_write : cmd_read;
            dram_addr <= {1'b1, ff_address[10:1]};      // 10 BIT

        end

        // Для корректного чтения требуется 3 такта, чтобы успел сигнал
        // Для записи слова требуется BURST Terminate
        3: if (ff_we)
        begin fn <= 6; command <= cmd_burst_term; end
        else  fn <= 4;

        // Перезарядка банка, закрытие строки
        6: begin

            fn       <= 7;
            command  <= cmd_precharge;
            dram_addr[10] <= 1'b1;

            if (ff_we == 1'b0) out <= (ff_address[0] ? dram_dq[15:8] : dram_dq[7:0]);

        end

        // Переход к IDLE
        7: begin

            st        <= ST_IDLE;
            fn        <= 0;
            command   <= cmd_nop;
            dram_udqm <= 1'b1;
            dram_ldqm <= 1'b1;
            ff_ready  <= 1'b1;

        end

    endcase

endcase

endmodule
