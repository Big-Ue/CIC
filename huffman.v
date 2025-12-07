module huffman (
    clk,
    reset,
    gray_valid,
    CNT_valid,
    CNT1,
    CNT2,
    CNT3,
    CNT4,
    CNT5,
    CNT6,
    code_valid,
    HC1,
    HC2,
    HC3,
    HC4,
    HC5,
    HC6,
    gray_data,
    M1,
    M2,
    M3,
    M4,
    M5,
    M6
);
  input clk;
  input reset;
  input gray_valid;
  input [7:0] gray_data;
  output reg CNT_valid;
  output reg [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
  output reg code_valid;
  output [7:0] HC1, HC2, HC3, HC4, HC5, HC6;
  output [7:0] M1, M2, M3, M4, M5, M6;

  parameter IDLE         = 3'd0,
          STATISTICS     = 3'd1,
          OUT_CNT        = 3'd2,
          INITIALIZATION = 3'd3,  
          COMBINATION    = 3'd4,
          SPLIT          = 3'd5,
          FINISH         = 3'd6;
  integer i;

  reg [7:0] CT[5:0];
  reg [5:0] A[5:0];
  reg [5:0] comb_high_stack[4:0];
  reg [5:0] comb_low_stack[4:0];
  reg [4:0] mask_index[5:0];
  reg [4:0] M[5:0];
  reg [4:0] HC[5:0];
  reg [2:0] state;
  reg [2:0] comb_index;
  reg [2:0] stack_cnt;
  reg reverse;
  wire [2:0] comb_high = comb_index + 3'd1;
  wire [2:0] comb_low = comb_index;
  wire sort_ok_flag =   (CT[0] <= CT[1] || (CT[0] == CT[1] && A[0] >= A[1]))
                    &&(CT[1] <= CT[2] || (CT[1] == CT[2] && A[1] >= A[2]))
                    &&(CT[2] <= CT[3] || (CT[2] == CT[3] && A[2] >= A[3]))
                    &&(CT[3] <= CT[4] || (CT[3] == CT[4] && A[3] >= A[4]))
                    &&(CT[4] <= CT[5] || (CT[4] == CT[5] && A[4] >= A[5]));
  assign M1  = {3'd0, M[0]};
  assign M2  = {3'd0, M[1]};
  assign M3  = {3'd0, M[2]};
  assign M4  = {3'd0, M[3]};
  assign M5  = {3'd0, M[4]};
  assign M6  = {3'd0, M[5]};
  assign HC1 = {3'd0, HC[0]};
  assign HC2 = {3'd0, HC[1]};
  assign HC3 = {3'd0, HC[2]};
  assign HC4 = {3'd0, HC[3]};
  assign HC5 = {3'd0, HC[4]};
  assign HC6 = {3'd0, HC[5]};
  always @(*) begin
    for (i = 0; i <= 5; i = i + 1) mask_index[i] = ~M[i] & {M[i][3:0], 1'b1};
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE:           state <= (gray_valid) ? STATISTICS : state;
        STATISTICS:     state <= (gray_valid) ? state : OUT_CNT;
        OUT_CNT:        state <= INITIALIZATION;
        INITIALIZATION: state <= (sort_ok_flag) ? COMBINATION : state;
        COMBINATION:    state <= (A[3] == 6'd0) ? SPLIT : INITIALIZATION;
        SPLIT:          state <= (stack_cnt == 3'd4) ? FINISH : state;
        FINISH:         state <= state;
        default:        state <= IDLE;
      endcase
    end
  end
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      CNT_valid <= 1'b0;
      CNT1 <= 8'd0;
      CNT2 <= 8'd0;
      CNT3 <= 8'd0;
      CNT4 <= 8'd0;
      CNT5 <= 8'd0;
      CNT6 <= 8'd0;
    end else begin
      CNT_valid <= (state == OUT_CNT);
      if (gray_valid) begin
        case (gray_data)
          8'h01: CNT1 <= CNT1 + 8'd1;
          8'h02: CNT2 <= CNT2 + 8'd1;
          8'h03: CNT3 <= CNT3 + 8'd1;
          8'h04: CNT4 <= CNT4 + 8'd1;
          8'h05: CNT5 <= CNT5 + 8'd1;
          8'h06: CNT6 <= CNT6 + 8'd1;
        endcase
      end
    end
  end
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      reverse <= 1'b0;
      comb_index <= 3'd0;
      for (i = 0; i <= 5; i = i + 1) begin
        CT[i] <= 8'd0;
        A[i]  <= 1'b1 << i;
      end
    end else begin
      case (state)
        OUT_CNT: begin
          CT[0] <= CNT1;
          CT[1] <= CNT2;
          CT[2] <= CNT3;
          CT[3] <= CNT4;
          CT[4] <= CNT5;
          CT[5] <= CNT6;
        end
        INITIALIZATION: begin
          reverse <= ~reverse;
          if (reverse) begin
            for (i = 1; i <= 4; i = i + 2) begin
              if (CT[i] > CT[i+1] || (CT[i] == CT[i+1] && A[i] < A[i+1])) begin
                CT[i]   <= CT[i+1];
                CT[i+1] <= CT[i];
                A[i]    <= A[i+1];
                A[i+1]  <= A[i];
              end
            end
          end else begin
            for (i = 0; i <= 5; i = i + 2) begin
              if (CT[i] > CT[i+1] || (CT[i] == CT[i+1] && A[i] < A[i+1])) begin
                CT[i]   <= CT[i+1];
                CT[i+1] <= CT[i];
                A[i]    <= A[i+1];
                A[i+1]  <= A[i];
              end
            end
          end
        end
        COMBINATION: begin
          CT[comb_high] <= CT[comb_high] + CT[comb_low];
          A[comb_high] <= A[comb_high] | A[comb_low];
          CT[comb_low] <= 8'd0;
          A[comb_low] <= 6'd0;
          comb_index <= comb_index + 3'd1;
        end
      endcase
    end
  end
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      for (i = 0; i <= 4; i = i + 1) begin
        comb_high_stack[i] <= 6'd0;
        comb_low_stack[i]  <= 6'd0;
      end
    end else begin
      if (state == COMBINATION || state == SPLIT) begin
        comb_high_stack[4] <= A[comb_high];
        comb_low_stack[4]  <= A[comb_low];
        for (i = 0; i <= 3; i = i + 1) begin
          comb_high_stack[i] <= comb_high_stack[i+1];
          comb_low_stack[i]  <= comb_low_stack[i+1];
        end
      end
    end
  end
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      stack_cnt <= 3'd0;
      for (i = 0; i <= 5; i = i + 1) begin
        HC[i] <= 5'd0;
        M[i]  <= 5'd0;
      end
    end else begin
      if (state == SPLIT) begin
        stack_cnt <= stack_cnt + 3'd1;
        for (i = 0; i <= 5; i = i + 1) begin
          HC[i] <= HC[i] | (mask_index[i] & {5{comb_low_stack[0][i]}});
          M[i]  <= (comb_high_stack[0][i] || comb_low_stack[0][i]) ? {M[i][3:0], 1'b1} : M[i];
        end
      end
    end
  end
  always @(posedge clk or posedge reset) begin
    if (reset) code_valid <= 1'b0;
    else code_valid <= (state == FINISH);
  end
endmodule

/*
// 2025-22-30 (19.00~19:53, 50m) : 完成 CNT 輸出，文檔閱讀理解。
// 2025-12-2  (1h55m) : 完成排序。
// area:19105
module huffman(clk, reset, gray_valid, CNT_valid, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
    code_valid, HC1, HC2, HC3, HC4, HC5, HC6, gray_data, M1, M2, M3, M4, M5, M6);

input clk;
input reset;
input gray_valid;
input [7:0] gray_data;
output reg CNT_valid;
output reg [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
output reg code_valid;
output [7:0] HC1, HC2, HC3, HC4, HC5, HC6;
output [7:0] M1, M2, M3, M4, M5, M6;
  
// always @(posedge clk or posedge reset) begin
//   if (reset) begin
//   end else begin
//   end
// end

//assign code_valid = 1'b0;


parameter A1 = 8'h01,
          A2 = 8'h02,
          A3 = 8'h03,
          A4 = 8'h04,
          A5 = 8'h05,
          A6 = 8'h06;

reg gray_valid_dely;
reg [1:0] cnt_state;

always @(posedge clk or posedge reset) begin
  if (reset) begin
    CNT1 <= 8'd0; 
    CNT2 <= 8'd0; 
    CNT3 <= 8'd0; 
    CNT4 <= 8'd0; 
    CNT5 <= 8'd0; 
    CNT6 <= 8'd0;
  end else begin
    if (gray_valid) begin
        case (gray_data)
            A1: CNT1 <= CNT1 + 8'd1;
            A2: CNT2 <= CNT2 + 8'd1;
            A3: CNT3 <= CNT3 + 8'd1;
            A4: CNT4 <= CNT4 + 8'd1;
            A5: CNT5 <= CNT5 + 8'd1;
            A6: CNT6 <= CNT6 + 8'd1;
        default: begin
            CNT1 <= CNT1; 
            CNT2 <= CNT2; 
            CNT3 <= CNT3; 
            CNT4 <= CNT4; 
            CNT5 <= CNT5; 
            CNT6 <= CNT6;
        end
        endcase
    end else begin
        CNT1 <= CNT1; 
        CNT2 <= CNT2; 
        CNT3 <= CNT3; 
        CNT4 <= CNT4; 
        CNT5 <= CNT5; 
        CNT6 <= CNT6;
    end
  end
end

always @(posedge clk or posedge reset) begin
  if (reset) begin
    cnt_state <= 2'd0;
  end else begin
    case (cnt_state)
      2'd0: cnt_state <= (gray_valid) ? 2'd1 : cnt_state;
      2'd1: cnt_state <= (!gray_valid) ? 2'd2 : cnt_state;
      2'd2: cnt_state <= 2'd3;
      2'd3: cnt_state <= cnt_state;
      default: cnt_state <= 2'd0;
    endcase
  end
end
always @(posedge clk or posedge reset) begin
  if (reset) CNT_valid <= 1'b0;
  else CNT_valid <= (cnt_state == 2'd2);
end







parameter IDLE = 3'd0,
          initialization = 3'd1,
          combination = 3'd2,
          split = 3'd3,
          out = 3'd4;

reg [2:0] state;
reg [2:0] cnt, cnt_num, cnt_out;
reg reverse;
reg [7:0] CNT [5:0];
reg [5:0] A [5:0];
reg [4:0] M [5:0];
reg [4:0] HC [5:0];
reg [5:0] add0 [4:0];
reg [5:0] add1 [4:0];

wire sort_ok_flag;
wire [2:0] low1, low2;


integer i, j;

always @(posedge clk or posedge reset) begin
  if (reset) begin
    state <= IDLE;
  end else begin
    case (state)
      IDLE: state <= (CNT_valid) ? initialization : state;
      initialization: state <= (sort_ok_flag) ? ((cnt == 3'd4) ? split : combination) : state;
      combination: state <= initialization;
      split: state <= out;
      out: state <= (cnt_out == 3'd4) ? IDLE : state;
      default: state <= IDLE;
    endcase
  end
end



assign sort_ok_flag = (CNT[0] <= CNT[1] || (CNT[0] == CNT[1] && A[0] > A[1]))
                    &&(CNT[1] <= CNT[2] || (CNT[1] == CNT[2] && A[1] > A[2]))
                    &&(CNT[2] <= CNT[3] || (CNT[2] == CNT[3] && A[2] > A[3]))
                    &&(CNT[3] <= CNT[4] || (CNT[3] == CNT[4] && A[3] > A[4]))
                    &&(CNT[4] <= CNT[5] || (CNT[4] == CNT[5] && A[4] > A[5]));

assign low1 = cnt_num;
assign low2 = cnt_num + 3'd1;

always @(posedge clk or posedge reset) begin
  if (reset) begin
    reverse <= 1'b0;
    cnt_num <= 3'd0;
    for (i=0; i<=5; i=i+1) begin 
      CNT[i] <= 8'd0;
      A[i] <= 1'b1 << i;
    end
  end else begin
    case (state)
      IDLE: begin
        CNT[0] <= (CNT_valid) ? CNT1 : 8'd0;
        CNT[1] <= (CNT_valid) ? CNT2 : 8'd0;
        CNT[2] <= (CNT_valid) ? CNT3 : 8'd0;
        CNT[3] <= (CNT_valid) ? CNT4 : 8'd0;
        CNT[4] <= (CNT_valid) ? CNT5 : 8'd0;
        CNT[5] <= (CNT_valid) ? CNT6 : 8'd0;
      end
      initialization: begin
        reverse <= ~reverse;
        if (reverse) begin
          for (i=1; i<5; i=i+2) begin
            if (CNT[i] > CNT[i+1] || (CNT[i] == CNT[i+1] && A[i] < A[i+1])) begin
              CNT[i] <= CNT[i+1];
              CNT[i+1] <= CNT[i];
              A[i] <= A[i+1];
              A[i+1] <= A[i];
            end
          end
        end else begin
          for (i=0; i<=5; i=i+2) begin
            if (CNT[i] > CNT[i+1] || (CNT[i] == CNT[i+1] && A[i] < A[i+1])) begin
              CNT[i] <= CNT[i+1];
              CNT[i+1] <= CNT[i];
              A[i] <= A[i+1];
              A[i+1] <= A[i];
            end 
          end
        end
      end
      combination: begin
        CNT[low1] <= 8'd0;
        CNT[low2] <= CNT[low1] + CNT[low2];
        A[low1] <= 3'd0;
        A[low2] <= A[low1] | A[low2];
        cnt_num <= cnt_num + 3'd1;
      end
    endcase
  end
end


always @(posedge clk or posedge reset) begin
  if (reset) begin
    cnt <= 3'd0;
  end else begin
    if (state == combination && cnt == 3'd4) begin
      cnt <= 3'd0;
    end else if (state == combination) begin
      cnt <= cnt + 3'd1;
    end else begin
      cnt <= cnt;
    end
  end
end


always @(posedge clk or posedge reset) begin
  if (reset) begin
    for (j=0; j<=4; j=j+1) begin
      add0[j] <= 6'd0;
      add1[j] <= 6'd0;
    end
  end else begin
    if (state == combination || state == split) begin
      add0[4] <= A[low2];
      add1[4] <= A[low1];
      for (j=0; j<=3; j=j+1) begin
        add0[j] <= add0[j+1];
        add1[j] <= add1[j+1];
      end
    end
  end
end

assign M1 = {3'd0, M[0]};
assign M2 = {3'd0, M[1]};
assign M3 = {3'd0, M[2]};
assign M4 = {3'd0, M[3]};
assign M5 = {3'd0, M[4]};
assign M6 = {3'd0, M[5]};

assign HC1 = {3'd0, HC[0]};
assign HC2 = {3'd0, HC[1]};
assign HC3 = {3'd0, HC[2]};
assign HC4 = {3'd0, HC[3]};
assign HC5 = {3'd0, HC[4]};
assign HC6 = {3'd0, HC[5]};

reg [2:0] M_decode [5:0];
always @(*) begin
  for (i=0; i<=5; i=i+1) begin
    case (M[i])
      5'b00000: M_decode[i] <= 3'd0;
      5'b00001: M_decode[i] <= 3'd1;
      5'b00011: M_decode[i] <= 3'd2;
      5'b00111: M_decode[i] <= 3'd3;
      5'b01111: M_decode[i] <= 3'd4;
      5'b11111: M_decode[i] <= 3'd5;
      default:  M_decode[i] <= 3'd0;
    endcase
  end
end

always @(posedge clk or posedge reset) begin
  if (reset) begin
    cnt_out <= 3'd0;
    for (i=0; i<=5; i=i+1) begin 
      HC[i] <= 5'd0;
      M[i]  <= 5'd0;
    end
  end else begin
    if (state == out) begin
      cnt_out <= cnt_out + 3'd1;
      for (i=0; i<=5; i=i+1) begin
        HC[i][M_decode[i]] <= (add1[cnt_out][i]);
        M[i]  <= (add0[cnt_out][i] || add1[cnt_out][i]) ? {M[i][3:0], 1'b1} : M[i];
      end 
    end
  end
end


always @(posedge clk or posedge reset) begin
  if (reset) begin
    code_valid <= 1'b0;
  end else begin
    if (state == IDLE && cnt_out == 3'd5) begin
      code_valid <= 1'b1;
    end 
  end
end


endmodule


// module sort(clk, reset, C_valid, Ci1, Ci2, Ci3, Ci4, Ci5, Ci6, 
// SBi0, SBi1, SBi2, SBi3, SBi4, SBi5, SBi6, 
// Co1, Co2, Co3, Co4, Co5, Co6, 
// SBo0, SBo1, SBo2, SBo3, SBo4, SBo5, SBo6,
// Co_valid);

// input clk;
// input reset;
// input C_valid;
// input [7:0] Ci1, Ci2, Ci3, Ci4, Ci5, Ci6;
// input [5:0] SBi0, SBi1, SBi2, SBi3, SBi4, SBi5, SBi6;
// output reg [7:0] Co1, Co2, Co3, Co4, Co5, Co6;
// output reg [5:0] SBo0, SBo1, SBo2, SBo3, SBo4, SBo5, SBo6;
// output reg Co_valid;

// reg reverse;

// always @(posedge clk or posedge reset) begin
//   if (reset) begin
//     reverse <= 1'b0;
//     Co1 <= 8'd0;
//     Co2 <= 8'd0;
//     Co3 <= 8'd0;
//     Co4 <= 8'd0;
//     Co5 <= 8'd0;
//     Co6 <= 8'd0;
//     SBo0 <= 6'd0;
//     SBo1 <= 6'd0;
//     SBo2 <= 6'd0;
//     SBo3 <= 6'd0;
//     SBo4 <= 6'd0;
//     SBo5 <= 6'd0;
//   end else begin
//     if (C_valid) begin

//     end else begin
//       Co1 <= Ci1;
//       Co2 <= Ci1;
//       Co3 <= Ci1;
//       Co4 <= Ci1;
//       Co5 <= Ci1;
//       Co6 <= Ci1;
//       SBo0 <= SBi0;
//       SBo1 <= SBi0;
//       SBo2 <= SBi0;
//       SBo3 <= SBi0;
//       SBo4 <= SBi0;
//       SBo5 <= SBi0;
//     end
//   end
// end


// endmodule 
*/
