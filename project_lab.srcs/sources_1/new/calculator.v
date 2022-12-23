`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/09/2021 07:31:43 PM
// Design Name: 
// Module Name: calculator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module calculator(
    input clk, input reset,
    input wire signed [26:0]   inputval,
    input wire        [2:0]    op,
    input wire                 en,
    output reg signed [26:0]   outputval
    );
    
    //////////////////////////////////
    // ALU
    reg  signed [26:0] currentval;     // current val in the accumulator
    wire signed [26:0] aluval;
    alu alu1(currentval, inputval, op, aluval);
    
    reg state;

    initial begin state = 0; currentval = 0; end
    always @(posedge clk) begin
        if(reset)       begin currentval = 0;           state = 0; end
        case(state)
            0: if(en)   begin currentval = aluval;      state = 1; end
            1: if(~en)  begin outputval = currentval;   state = 0; end
        endcase
    end
endmodule

module alu(
    input       signed  [26:0]  A,
    input       signed  [26:0]  B,
    input               [2:0]   op,
    output reg  signed  [26:0]  S
    );
    reg signed  [26:0]  f;
    wire negative;
    assign negative = A[26];
    
    always@(A or B or op)begin
        f = A;
        if(negative) f = -A;
        if(f>9999) S = A;
        else begin
            case(op)
                0: S = A+B;
                1: S = A-B;
                2: S = A*B;
                3: begin
                    if(B==0) S = 10000;
                    else S = A/B;
                   end
            endcase
        end
        case(op)
            4: S = A;
            5: S = 0;
        endcase
    end
endmodule