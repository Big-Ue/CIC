module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output match;
output [4:0] match_index;
output valid;
// reg match;
// reg [4:0] match_index;
// reg valid;

// always @(posedge clk or posedge reset) begin
//   if (reset) begin
//   end else begin
//   end
// end

assign valid = 1'b0;

parameter READ_DATA = 0;
integer i;
reg [3:0] state;
reg [7:0] stringBuff [31:0];
reg [7:0] patternBuff [7:0];
reg [4:0] stringIndex;
reg [2:0] patternIndex;

always @(posedge clk or posedge reset) begin
  if (reset) begin
    state <= READ_DATA;
  end else begin
    case (state)
      default: state <= READ_DATA;
    endcase
  end
end

always @(posedge clk or posedge reset) begin
  if (reset) begin
    stringIndex  <= 5'd0;
    patternIndex <= 3'd0;
    for (i=0; i<=31; i=i+1) stringBuff[i]  <= 8'd0;
    for (i=0; i<=7; i=i+1)  patternBuff[i] <= 8'd0;
  end else begin
    case (state)
      READ_DATA: begin
        if (isstring) begin
          stringIndex <= stringIndex + 5'd1;
          stringBuff[stringIndex] <= chardata;
        end
        if (ispattern) begin
          patternIndex <= patternIndex + 3'd1;
          patternBuff[patternIndex] <= chardata;
        end
      end
    endcase
  end
end






endmodule
